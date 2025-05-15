class TasksController < ApplicationController
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
    @task = @todo.tasks.new(tasks_params)
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
    if @task.update(tasks_params)
      redirect_to project_todos_path(@project), notice: "Task has been updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @task = Task.find(params[:id])
    @task.destroy
    redirect_to project_todos_path(@project), notice: "Task has been deleted successfully."
  end

  def set_context
    puts "params: #{params.inspect}"
    @todo = Todo.find(params[:todo_id])
    @project = Project.find(params[:project_id])
  end

  def tasks_params
    params.require(:task).permit(:title, :done)
  end
end
