class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context

  def index
    @tasks = @todo.tasks
  end

  def show
    @task = Task.find(params[:id])
    @todo = Todo.find(params[:todo_id])
    @project = Project.find(params[:project_id])
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
    @task = Task.find(params[:id])
  end
  def update
    @task = Task.find(params[:id])
    logger.debug "params: #{params.inspect}"
    logger.debug "params: #{tasks_params}"
    if @task.update(tasks_params)
      if params[:from] == "full_form"
        redirect_to project_todo_task_path(@project), notice: "Task has been updated successfully."
      else
        redirect_to project_todos_path(@project), notice: "Task has been updated successfully."
      end
    else
      render :edit
    end
  end

  def add_comment
    @task = Task.find(params[:id])
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
    @task = Task.find(params[:id])
    @task.destroy
    redirect_to project_todos_path(@project), notice: "Task has been deleted successfully."
  end

  def set_context
    @todo = Todo.find(params[:todo_id])
    @project = Project.find(params[:project_id])
  end

  def tasks_params
    params.require(:task).permit(:title, :done, :from, :notes, :due_date)
  end
end
