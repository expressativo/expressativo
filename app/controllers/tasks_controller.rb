class TasksController < ApplicationController
  before_action :set_context

  def index
    @tasks = @todo.tasks
  end

  def new
    @task = Task.new
  end

  def create
    @task = @todo.tasks.new(tasks_params)
    if @task.save
      redirect_to project_todos_path(@project), notice: "Task has been created successfully."
    else
      render :new
    end
  end

  def set_context
    puts "params: #{params.inspect}"
    @todo = Todo.find(params[:todo_id])
    @project = Project.find(params[:project_id])
  end

  def tasks_params
    params.require(:task).permit(:title, :completed)
  end
end
