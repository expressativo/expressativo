class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context, except: :my_task
  before_action :set_task, only: %i[show edit update destroy add_comment search_members update_position publish_public unpublish_public calendar]
  before_action :require_non_viewer_for_task!, only: %i[edit update destroy update_position publish_public unpublish_public]
  before_action :require_assigned_task_for_viewer!, only: %i[show add_comment]

  def index
    @tasks = @todo.tasks
  end

  def show
    remember_task_return_to
    @back_url, @back_label = task_back_link
  end

  def new
    if @project.task_templates.any? && params[:template_id].blank? && params[:blank].blank?
      @templates = @project.task_templates.order(:name)
      render :choose_template
    else
      @task = Task.new
      if params[:template_id].present?
        @template = @project.task_templates.find_by(id: params[:template_id])
        if @template
          @task.title = @template.title
        end
      end
    end
  end

  def create
    @task = @todo.tasks.new(tasks_params.merge(created_by: current_user))
    column = assign_board_column if params[:from] == "board" && params[:column_id].present?
    from_add_tasks = params[:from] == "add_tasks" && params[:board_id].present?
    from_board = column.present?

    respond_to do |format|
      if @task.save
        apply_template_notes(@task)
        if from_board
          format.json { render_board_task_json(column) }
          format.html { redirect_to project_board_path(@project, column.board), notice: "Tarea creada correctamente." }
        elsif from_add_tasks
          board = @project.boards.find(params[:board_id])
          format.html { redirect_to add_tasks_project_board_path(@project, board) }
        else
          format.turbo_stream
          format.html { redirect_to project_todos_path(@project), notice: "Task has been created successfully." }
        end
      elsif from_board
        format.json { render json: { success: false, errors: @task.errors.full_messages }, status: :unprocessable_entity }
      elsif from_add_tasks
        board = @project.boards.find(params[:board_id])
        format.html { redirect_to add_tasks_project_board_path(@project, board), alert: @task.errors.full_messages.to_sentence }
      else
        render :new
      end
    end
  end

  def edit
  end

  def update
    if @task.update(tasks_params)
      if params[:from] == "full_form" || params[:from] == "show"
        redirect_to project_todo_task_path(@project, @todo, @task), notice: "Tarea actualizada correctamente."
      elsif params[:from] == "my_task"
        redirect_to my_task_path, notice: "Tarea actualizada correctamente."
      else
        redirect_to project_todos_path(@project), notice: "Tarea actualizada correctamente."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def add_comment
    @comment = @task.comments.new(comment_params)
    @comment.user = current_user
    if @comment.save
      redirect_to project_todo_task_path(@project, @todo, @task), notice: "Comment has been added successfully."
    else
      @back_url, @back_label = task_back_link
      render :show, status: :unprocessable_entity
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def destroy
    return_to = stored_task_return_to
    forget_task_return_to
    @task.destroy
    redirect_to return_to || project_todos_path(@project), notice: "Task has been deleted successfully.", status: :see_other
  end

  def calendar
    return redirect_to project_todo_task_path(@project, @todo, @task), alert: "Esta tarea no tiene fecha de vencimiento." unless @task.due_date.present?

    ics = @task.to_ics(task_url: project_todo_task_url(@project, @todo, @task), host: request.host)
    send_data ics,
              type: "text/calendar; charset=utf-8",
              disposition: "attachment",
              filename: "tarea-#{@task.id}.ics"
  end

  def publish_public
    @task.publish_publicly!
    redirect_to project_todo_task_path(@project, @todo, @task), notice: "Link público generado."
  end

  def unpublish_public
    @task.unpublish_publicly!
    redirect_to project_todo_task_path(@project, @todo, @task), notice: "Link público revocado."
  end

  def update_position
    new_position = params[:position].to_i

    Task.transaction do
      @task.update!(list_position: new_position)

      @todo.tasks.not_done.where.not(id: @task.id).order(:list_position, :id).each_with_index do |t, i|
        pos = i >= new_position ? i + 1 : i
        t.update_column(:list_position, pos) if t.list_position != pos
      end
    end

    head :no_content
  end

  # task assigned to current user
  def my_task
    @tasks = current_user.tasks
      .not_done
      .includes(:assigned_users, todo: :project)
      .order(Arel.sql("CASE WHEN due_date IS NULL THEN 1 ELSE 0 END, due_date ASC"))

    respond_to do |format|
      format.html
      format.turbo_stream
      format.json { render json: @tasks }
    end
  end

  def search_members
    query = params[:filter].to_s.downcase

    users = @project.users.where(
      "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?",
      "%#{query}%", "%#{query}%", "%#{query}%"
    ).limit(8)

    render partial: "tasks/mention_prompt_items", locals: { users: users }
  end

  private

  TASK_RETURN_TO_KEY = "task_return_to".freeze
  TASK_RETURN_TO_LIMIT = 10

  # Guarda de dónde vino el usuario al abrir la tarea (lista, tablero, calendario,
  # Mis tareas, notificaciones...). Las acciones internas de la tarea (editar,
  # comentar, cambiar estado, asignar) redirigen al propio show y cambian el
  # Referer, así que el origen se persiste en sesión por tarea.
  def remember_task_return_to
    referer = internal_referer_path
    return if referer.blank? || referer.start_with?(project_todo_task_path(@project, @todo, @task))

    entries = session[TASK_RETURN_TO_KEY].is_a?(Hash) ? session[TASK_RETURN_TO_KEY].dup : {}
    entries.delete(@task.id.to_s)
    entries[@task.id.to_s] = referer
    session[TASK_RETURN_TO_KEY] = entries.to_a.last(TASK_RETURN_TO_LIMIT).to_h
  end

  def stored_task_return_to
    entries = session[TASK_RETURN_TO_KEY]
    entries[@task.id.to_s] if entries.is_a?(Hash)
  end

  def forget_task_return_to
    session[TASK_RETURN_TO_KEY]&.delete(@task.id.to_s) if session[TASK_RETURN_TO_KEY].is_a?(Hash)
  end

  # Solo paths del propio host, para evitar open redirects.
  def internal_referer_path
    return if request.referer.blank?

    uri = URI.parse(request.referer)
    return unless uri.host == request.host

    [ uri.path, uri.query ].compact.join("?")
  rescue URI::InvalidURIError
    nil
  end

  def task_back_link
    url = stored_task_return_to
    return [ project_todo_path(@project, @todo), "Volver a #{@todo.name}" ] if url.blank?

    path = url.split("?").first
    label =
      case path
      when %r{\A/projects/\d+/boards} then "Volver al tablero"
      when %r{\A/projects/\d+/calendar} then "Volver al calendario"
      when %r{\A/projects/\d+/timeline} then "Volver al timeline"
      when %r{\A/projects/\d+/todos/\d+\z} then "Volver a la lista"
      when %r{\A/projects/\d+/todos} then "Volver a To-dos"
      when %r{\A/projects/\d+/documents|\A/documents} then "Volver al documento"
      when %r{\A/my_task} then "Volver a Mis tareas"
      when %r{\A/notifications} then "Volver a notificaciones"
      else "Volver"
      end
    [ url, label ]
  end

  def set_context
    @project = Project.for_user(current_user).find(params[:project_id])
    @todo = @project.todos.find(params[:todo_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "El recurso solicitado no existe o no tienes acceso."
  end

  def require_non_viewer_for_task!
    require_non_viewer!(@project)
  end

  def require_assigned_task_for_viewer!
    return unless @project.viewer?(current_user)
    return if @task.assigned_users.include?(current_user)

    redirect_to project_todos_path(@project), alert: "Solo puedes ver las tareas que tienes asignadas."
  end

  def set_task
    @task = @todo.tasks.includes(:assigned_users, :created_by, :custom_field_values, :documents, comments: :user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to project_todos_path(@project), alert: "La tarea que buscas no existe o fue eliminada."
  end

  def apply_template_notes(task)
    return if params[:template_id].blank?

    template = @project.task_templates.find_by(id: params[:template_id])
    return unless template&.notes&.body&.present?

    task.notes = template.notes.body.to_s
    task.save
  end

  def tasks_params
    params.require(:task).permit(:title, :completed, :status, :from, :notes, :due_date, :column_id)
  end

  def assign_board_column
    column = Column.joins(:board).where(boards: { project_id: @project.id }).find_by(id: params[:column_id])
    return unless column

    @task.column = column
    @task.position = (column.tasks.maximum(:position) || -1) + 1
    @task.status = "done" if column.done?

    column
  end

  def render_board_task_json(column)
    board = column.board
    @task = @todo.tasks.includes(:todo, :created_by, :assigned_users).find(@task.id)

    render json: {
      success: true,
      todo_name: @todo.name,
      task_count: column.tasks.count,
      task_html: render_to_string(
        partial: "boards/task_card",
        locals: { task: @task, board: board, project: @project },
        formats: [ :html ]
      )
    }
  end
end
