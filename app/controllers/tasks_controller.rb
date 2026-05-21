class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context, except: :my_task
  before_action :set_task, only: %i[show edit update destroy add_comment search_members]

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
    respond_to do |format|
      if @task.save
        format.turbo_stream
        format.html { redirect_to project_todos_path(@project), notice: "Task has been created successfully." }
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
    query = params[:q].to_s.downcase

    users = @project.users.where(
      "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?",
      "%#{query}%", "%#{query}%", "%#{query}%"
    ).limit(5)

    render json: {
      users: users.map do |user|
        {
          id: user.id,
          name: user.full_name.presence || user.email,
          email: user.email,
          initials: user.full_name.present? ? user.full_name.split.map(&:first).join.upcase : user.email[0].upcase
        }
      end
    }
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
end
