class BoardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_board, only: [ :show, :edit, :update, :destroy, :add_tasks ]

  def index
    @boards = @project.boards
  end

  def show
    # Obtener todos los usuarios del proyecto para el filtro
    @project_users = @project.users.order(:first_name, :last_name)
    
    # Construir query base de columnas
    columns_query = @board.columns.includes(tasks: [ :todo, :created_by, :assigned_users ])
    
    # Aplicar filtro si existe
    if params[:assignee_id].present?
      if params[:assignee_id] == "unassigned"
        # Filtrar tareas sin asignar
        @columns = columns_query.map do |column|
          filtered_tasks = column.tasks.select { |task| task.assigned_users.empty? }
          column.define_singleton_method(:tasks) { filtered_tasks }
          column
        end
      else
        # Filtrar por usuario específico
        assignee_id = params[:assignee_id].to_i
        @columns = columns_query.map do |column|
          filtered_tasks = column.tasks.select { |task| task.assigned_users.pluck(:id).include?(assignee_id) }
          column.define_singleton_method(:tasks) { filtered_tasks }
          column
        end
      end
    else
      @columns = columns_query
    end
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

  def attach_multiple_tasks
    column = Column.find(params[:column_id])
    @board = column.board
    task_ids = params[:task_ids] || []

    if task_ids.empty?
      flash[:alert] = "No se seleccionaron tareas."
      redirect_to add_tasks_project_board_path(@project, @board)
      return
    end

    # Get all tasks and update them in batch
    tasks = Task.where(id: task_ids, column_id: nil)
    current_position = column.tasks.count

    tasks.each_with_index do |task, index|
      task.update(column: column, position: current_position + index)
    end

    flash[:notice] = "#{tasks.count} tarea(s) agregada(s) a #{column.title}."
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
