class TodosController < ApplicationController
    before_action :authenticate_user!
    before_action :set_project
    before_action :set_todo, only: [ :edit, :update, :destroy, :completed_tasks ]

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
    end

    def update
      if @todo.update(todo_params)
        redirect_to project_todos_path(@project), notice: "Todo has sido actualizado con éxito."
      else
        render :edit
      end
    end

    def destroy
      if @todo.tasks.pending.any?
        redirect_to edit_project_todo_path(@project, @todo), alert: "No se puede eliminar el Todo porque tiene tareas pendientes."
      else
        @todo.destroy
        redirect_to project_todos_path(@project), notice: "Todo eliminado correctamente."
      end
    end

    def completed_tasks
      @completed_tasks = @todo.tasks.where(done: true)
    end

    private
    def set_project
      @project = Project.find(params[:project_id])
    end

    def set_todo
      @todo = @project.todos.find(params[:id])
    end

    def todo_params
      params.require(:todo).permit(:name, :completed)
    end
end
