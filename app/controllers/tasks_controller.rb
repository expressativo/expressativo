class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context, except: :my_task
  before_action :set_task, only: %i[show edit update destroy add_comment search_members update_position]

  def index
    @tasks = @todo.tasks
  end

  def show
  end

  def new
    @task = Task.new
  end

  def create
    @task = @todo.tasks.new(tasks_params.merge(created_by: current_user))
    column = assign_board_column if params[:from] == "board" && params[:column_id].present?
    from_add_tasks = params[:from] == "add_tasks" && params[:board_id].present?
    from_board = column.present?

    respond_to do |format|
      if @task.save
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
      else
        redirect_to project_todos_path(@project), notice: "Tarea actualizada correctamente."
      end
    else
      render :edit
    end
  end

  def add_comment
    @comment = @task.comments.new(comment_params)
    @comment.user = current_user
    if @comment.save
      redirect_to project_todo_task_path(@project, @todo, @task), notice: "Comment has been added successfully."
    else
      render :show
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def destroy
    @task.destroy
    redirect_to project_todos_path(@project), notice: "Task has been deleted successfully."
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
      .includes(todo: :project)
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

  def set_context
    @project = Project.for_user(current_user).find(params[:project_id])
    @todo = @project.todos.find(params[:todo_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "El recurso solicitado no existe o no tienes acceso."
  end

  def set_task
    @task = @todo.tasks.includes(:assigned_users, :created_by, :publication, comments: :user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to project_todos_path(@project), alert: "La tarea que buscas no existe o fue eliminada."
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
