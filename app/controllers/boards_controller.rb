class BoardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_board, only: [:show, :edit, :update, :destroy, :add_tasks]

  def index
    @boards = @project.boards
  end

  def show
    @columns = @board.columns.includes(tasks: [:todo, :created_by])
  end

  def new
    @board = @project.boards.new
  end

  def create
    @board = @project.boards.new(board_params)

    if @board.save
      flash[:notice] = "Tablero creado exitosamente."
      redirect_to project_board_path(@project, @board)
    else
      flash[:alert] = "Error al crear el tablero."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @board.update(board_params)
      flash[:notice] = "Tablero actualizado exitosamente."
      redirect_to project_board_path(@project, @board)
    else
      flash[:alert] = "Error al actualizar el tablero."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @board.destroy
    flash[:notice] = "Tablero eliminado exitosamente."
    redirect_to project_boards_path(@project)
  end

  def add_tasks
    @todos = @project.todos.includes(:tasks)
  end

  def attach_task
    @board = @project.boards.find(params[:board_id])
    @task = Task.find(params[:task_id])
    column = @board.columns.find(params[:column_id])

    @task.update(column: column, position: column.tasks.count)

    flash[:notice] = "Tarea agregada al tablero."
    redirect_to project_board_path(@project, @board)
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end

  def set_board
    @board = @project.boards.find(params[:id])
  end

  def board_params
    params.require(:board).permit(:title, :description)
  end
end
