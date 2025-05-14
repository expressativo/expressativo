class TodosController < ApplicationController
    before_action :set_project


    def index
      @todos = @project.todos
    end

    def new
      @todo = Todo.new
    end

    def create
      puts "params: #{params.inspect}"
      @todo = @project.todos.new(todo_params)
      if @todo.save
        redirect_to project_todos_path(@project), notice: "Todo has sido creado con éxito."
      else
        render :new
      end
    end

    private
    def set_project
      @project = Project.find(params[:project_id])
    end

    def todo_params
      params.require(:todo).permit(:name, :completed)
    end
end
