# Endpoint MCP remoto (transporte Streamable HTTP, sin sesión).
#
#   claude mcp add --transport http tivo https://<host>/mcp
#
# Sin token responde 401 con la URL de metadatos OAuth, así el cliente
# descubre solo el flujo de autorización (ver OauthController).
class McpController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [ :stream ]

  # POST /mcp
  def create
    payload = JSON.parse(request.raw_post)
    server = Mcp::Server.new(current_api_user, base_url: request.base_url)

    responses = if payload.is_a?(Array)
      payload.filter_map { |message| server.handle(message) }.presence
    else
      server.handle(payload)
    end

    responses ? render(json: responses) : head(:accepted)
  rescue JSON::ParserError
    render json: { jsonrpc: "2.0", id: nil, error: { code: -32700, message: "Parse error" } }, status: :bad_request
  end

  # GET/DELETE /mcp — no ofrecemos stream SSE ni sesiones.
  def stream
    head :method_not_allowed
  end

  private

  def authenticate_api_user!
    return if current_api_user

    response.headers["WWW-Authenticate"] =
      %(Bearer resource_metadata="#{request.base_url}/.well-known/oauth-protected-resource")
    render json: { error: "unauthorized" }, status: :unauthorized
  end
end
