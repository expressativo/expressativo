module Mcp
  # Servidor MCP (Model Context Protocol) sobre JSON-RPC 2.0, transporte
  # "Streamable HTTP" sin estado: cada POST /mcp trae un mensaje y se responde
  # con JSON plano. Las herramientas viven en Mcp::Tools.
  class Server
    PROTOCOL_VERSIONS = %w[2025-06-18 2025-03-26 2024-11-05].freeze
    SERVER_INFO = { name: "tivo", title: "Tivo", version: "1.0.0" }.freeze
    INSTRUCTIONS = <<~TEXT.freeze
      Tivo es un gestor de proyectos. Jerarquía: proyecto → listas (todos) → tareas.
      Los documentos pertenecen a un proyecto y pueden estar en carpetas.
      Usá list_projects para descubrir IDs antes de crear o editar.
      Las notas de tareas y el contenido de documentos se escriben en Markdown.
    TEXT

    class Error < StandardError
      attr_reader :code

      def initialize(code, message)
        @code = code
        super(message)
      end
    end

    def initialize(user, base_url:)
      @tools = Tools.new(user, base_url: base_url)
    end

    # Devuelve el hash de respuesta, o nil si el mensaje era una notificación.
    def handle(message)
      return error_response(nil, -32600, "Invalid Request") unless message.is_a?(Hash) && message["jsonrpc"] == "2.0"

      id = message["id"]
      notification = !message.key?("id")
      result = dispatch(message["method"].to_s, message["params"] || {})
      notification ? nil : { jsonrpc: "2.0", id: id, result: result }
    rescue Error => e
      notification ? nil : error_response(id, e.code, e.message)
    end

    private

    def dispatch(method, params)
      case method
      when "initialize"
        requested = params["protocolVersion"]
        {
          protocolVersion: PROTOCOL_VERSIONS.include?(requested) ? requested : PROTOCOL_VERSIONS.first,
          capabilities: { tools: { listChanged: false } },
          serverInfo: SERVER_INFO,
          instructions: INSTRUCTIONS
        }
      when "ping", "notifications/initialized", "notifications/cancelled"
        {}
      when "tools/list"
        { tools: Tools::DEFINITIONS }
      when "tools/call"
        call_tool(params["name"].to_s, params["arguments"] || {})
      else
        raise Error.new(-32601, "Method not found: #{method}")
      end
    end

    def call_tool(name, arguments)
      raise Error.new(-32602, "Unknown tool: #{name}") unless Tools::DEFINITIONS.any? { |t| t[:name] == name }

      data = @tools.call(name, arguments)
      { content: [ { type: "text", text: JSON.pretty_generate(data) } ] }
    rescue Tools::ToolError, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      # Los errores de herramienta se devuelven como resultado para que el
      # modelo los vea y pueda corregir los argumentos.
      message = e.is_a?(ActiveRecord::RecordNotFound) ? "No encontrado o sin acceso." : e.message
      { content: [ { type: "text", text: message } ], isError: true }
    end

    def error_response(id, code, message)
      { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
    end
  end
end
