class TodosController < ApplicationController
    before_action :set_project


    def index
      @todos = @project.todos
    end

    def new
      @todo = Todo.new
    end

    def create
      @todo = @project.todos.new(todo_params)
      if @todo.save
        redirect_to project_todos_path(@project), notice: "Todo has sido creado con éxito."
      else
        render :new
      end
    end

    def edit
      @todo = @project.todos.find(params[:id])
    end
    def update
      @todo = @project.todos.find(params[:id])
      if @todo.update(todo_params)
        redirect_to project_todos_path(@project), notice: "Todo has sido actualizado con éxito."
      else
        render :edit
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
