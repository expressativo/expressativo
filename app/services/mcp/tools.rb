module Mcp
  # Herramientas expuestas por el servidor MCP. Todas actúan en nombre de
  # @user y solo sobre proyectos donde es owner o member (los viewers no
  # tienen acceso a documentos ni pueden editar tareas en la app web).
  class Tools
    class ToolError < StandardError; end

    STATUS_DESCRIPTION = "pending | in_progress | done".freeze

    DEFINITIONS = [
      {
        name: "list_projects",
        title: "Listar proyectos",
        description: "Lista los proyectos activos del usuario con sus listas de tareas (todos).",
        inputSchema: { type: "object", properties: {} },
        annotations: { readOnlyHint: true }
      },
      {
        name: "list_tasks",
        title: "Listar tareas",
        description: "Lista las tareas de una lista (todo). Opcionalmente filtra por estado.",
        inputSchema: {
          type: "object",
          properties: {
            todo_id: { type: "integer", description: "ID de la lista (todo)" },
            status: { type: "string", enum: Task::STATUSES, description: STATUS_DESCRIPTION }
          },
          required: [ "todo_id" ]
        },
        annotations: { readOnlyHint: true }
      },
      {
        name: "get_task",
        title: "Ver tarea",
        description: "Devuelve una tarea con sus notas, responsables y documentos vinculados.",
        inputSchema: {
          type: "object",
          properties: { task_id: { type: "integer" } },
          required: [ "task_id" ]
        },
        annotations: { readOnlyHint: true }
      },
      {
        name: "create_task",
        title: "Crear tarea",
        description: "Crea una tarea en una lista (todo).",
        inputSchema: {
          type: "object",
          properties: {
            todo_id: { type: "integer", description: "ID de la lista (todo) donde crear la tarea" },
            title: { type: "string" },
            notes: { type: "string", description: "Notas en Markdown" },
            due_date: { type: "string", description: "Fecha ISO 8601, ej. 2026-11-05 o 2026-11-05T15:00" },
            status: { type: "string", enum: Task::STATUSES, description: STATUS_DESCRIPTION }
          },
          required: [ "todo_id", "title" ]
        }
      },
      {
        name: "update_task",
        title: "Editar tarea",
        description: "Edita una tarea. Solo se modifican los campos enviados; due_date vacío la elimina.",
        inputSchema: {
          type: "object",
          properties: {
            task_id: { type: "integer" },
            title: { type: "string" },
            notes: { type: "string", description: "Notas en Markdown (reemplaza las actuales)" },
            due_date: { type: "string", description: "Fecha ISO 8601, o vacío para quitarla" },
            status: { type: "string", enum: Task::STATUSES, description: STATUS_DESCRIPTION }
          },
          required: [ "task_id" ]
        },
        annotations: { idempotentHint: true }
      },
      {
        name: "list_documents",
        title: "Listar documentos",
        description: "Lista los documentos y carpetas de un proyecto (sin el contenido).",
        inputSchema: {
          type: "object",
          properties: {
            project_id: { type: "integer" },
            include_archived: { type: "boolean", default: false }
          },
          required: [ "project_id" ]
        },
        annotations: { readOnlyHint: true }
      },
      {
        name: "get_document",
        title: "Ver documento",
        description: "Devuelve un documento con su contenido (texto plano y HTML).",
        inputSchema: {
          type: "object",
          properties: { document_id: { type: "integer" } },
          required: [ "document_id" ]
        },
        annotations: { readOnlyHint: true }
      },
      {
        name: "create_document",
        title: "Crear documento",
        description: "Crea un documento de texto en un proyecto. Se crea como borrador salvo que se indique status published.",
        inputSchema: {
          type: "object",
          properties: {
            project_id: { type: "integer" },
            name: { type: "string" },
            content: { type: "string", description: "Contenido en Markdown" },
            folder_id: { type: "integer", description: "Carpeta destino (opcional, ver list_documents)" },
            status: { type: "string", enum: %w[draft published], default: "draft" }
          },
          required: [ "project_id", "name" ]
        }
      },
      {
        name: "update_document",
        title: "Editar documento",
        description: "Edita un documento de texto. Solo se modifican los campos enviados; content reemplaza todo el contenido.",
        inputSchema: {
          type: "object",
          properties: {
            document_id: { type: "integer" },
            name: { type: "string" },
            content: { type: "string", description: "Contenido completo en Markdown" },
            status: { type: "string", enum: %w[draft published archived] }
          },
          required: [ "document_id" ]
        },
        annotations: { idempotentHint: true }
      }
    ].freeze

    def initialize(user, base_url:)
      @user = user
      @base_url = base_url
    end

    def call(name, args)
      send(name, args.to_h.with_indifferent_access)
    end

    private

    def list_projects(_args)
      Project.where(id: project_ids).active.includes(:todos).order(updated_at: :desc).map do |project|
        {
          id: project.id,
          title: project.title,
          description: project.description,
          todos: project.todos.select { |t| !t.archived }.sort_by(&:name).map { |t| { id: t.id, name: t.name } }
        }
      end
    end

    def list_tasks(args)
      todo = find_todo(args[:todo_id])
      tasks = todo.tasks.list_ordered
      if args[:status].present?
        validate_status!(args[:status])
        tasks = tasks.where(status: args[:status])
      end
      tasks.map { |task| task_summary(task) }
    end

    def get_task(args)
      task = find_task(args[:task_id])
      task_summary(task).merge(
        notes: task.notes&.body&.to_plain_text.to_s.strip,
        assignees: task.assigned_users.map { |u| { id: u.id, name: u.full_name, email: u.email } },
        documents: task.documents.map { |d| { id: d.id, name: d.name } },
        url: url_helpers.project_todo_task_url(task.todo.project_id, task.todo_id, task, **url_options)
      )
    end

    def create_task(args)
      todo = find_todo(args[:todo_id])
      task = todo.tasks.new(created_by: @user)
      assign_task_attributes(task, args.merge(title: args[:title].to_s))
      task.save!
      get_task(task_id: task.id)
    end

    def update_task(args)
      task = find_task(args[:task_id])
      assign_task_attributes(task, args)
      task.save!
      get_task(task_id: task.id)
    end

    def list_documents(args)
      project = find_project(args[:project_id])
      documents = project.documents.visible_to(@user).includes(:folder).order(:name)
      documents = documents.not_archived unless ActiveModel::Type::Boolean.new.cast(args[:include_archived])
      {
        folders: project.folders.order(:name).map { |f| { id: f.id, name: f.name, parent_folder_id: f.parent_folder_id } },
        documents: documents.map { |d| document_summary(d) }
      }
    end

    def get_document(args)
      document = find_document(args[:document_id])
      document_summary(document).merge(
        content_text: document.body&.body&.to_plain_text.to_s.strip,
        content_html: document.body&.body&.to_html.to_s,
        file_name: document.file.attached? ? document.file.filename.to_s : nil
      )
    end

    def create_document(args)
      project = find_project(args[:project_id])
      document = project.documents.new(created_by: @user, document_type: :document, name: args[:name])
      document.folder = project.folders.find(args[:folder_id]) if args[:folder_id].present?
      document.status = document_status(args[:status], allowed: %w[draft published]) if args[:status].present?
      document.body = markdown_to_html(args[:content]) if args.key?(:content)
      document.save!
      get_document(document_id: document.id)
    end

    def update_document(args)
      document = find_document(args[:document_id])
      raise ToolError, "Los documentos de tipo archivo no se pueden editar." if document.file?
      if args[:status].present? && args[:status] != document.status && !document.can_be_published_by?(@user)
        raise ToolError, "Solo el autor o el owner del proyecto puede cambiar el estado del documento."
      end

      document.name = args[:name] if args.key?(:name)
      document.body = markdown_to_html(args[:content]) if args.key?(:content)
      document.status = document_status(args[:status]) if args[:status].present?
      document.save!
      get_document(document_id: document.id)
    end

    # --- Acceso ---

    def project_ids
      @project_ids ||= ProjectUser.where(user_id: @user.id, role: %w[owner member]).pluck(:project_id)
    end

    def find_project(id)
      Project.where(id: project_ids).find(id)
    end

    def find_todo(id)
      Todo.where(project_id: project_ids).find(id)
    end

    def find_task(id)
      Task.joins(:todo).where(todos: { project_id: project_ids }).find(id)
    end

    def find_document(id)
      Document.where(project_id: project_ids).visible_to(@user).find(id)
    end

    # --- Helpers ---

    def assign_task_attributes(task, args)
      task.title = args[:title] if args.key?(:title)
      task.notes = markdown_to_html(args[:notes]) if args.key?(:notes)
      task.due_date = parse_time(args[:due_date]) if args.key?(:due_date)
      if args[:status].present?
        validate_status!(args[:status])
        task.status = args[:status]
      end
    end

    def validate_status!(status)
      raise ToolError, "status inválido. Valores: #{STATUS_DESCRIPTION}" unless Task::STATUSES.include?(status)
    end

    def document_status(status, allowed: Document.statuses.keys)
      raise ToolError, "status inválido. Valores: #{allowed.join(' | ')}" unless allowed.include?(status)

      status
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s) || raise(ArgumentError)
    rescue ArgumentError
      raise ToolError, "Fecha inválida: #{value}. Usá formato ISO 8601 (ej. 2026-11-05)."
    end

    def markdown_to_html(markdown)
      return "" if markdown.blank?

      Commonmarker.to_html(markdown.to_s, options: {
        extension: { strikethrough: true, autolink: true, tagfilter: true, table: true, tasklist: true, header_ids: nil },
        render: { unsafe: false }
      })
    end

    def task_summary(task)
      {
        id: task.id,
        todo_id: task.todo_id,
        title: task.title,
        status: task.status,
        due_date: task.due_date&.iso8601,
        updated_at: task.updated_at.iso8601
      }
    end

    def document_summary(document)
      {
        id: document.id,
        project_id: document.project_id,
        folder_id: document.folder_id,
        name: document.name,
        status: document.status,
        type: document.document_type,
        updated_at: document.updated_at.iso8601,
        url: url_helpers.document_url(document, **url_options)
      }
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end

    def url_options
      { host: @base_url }
    end
  end
end
