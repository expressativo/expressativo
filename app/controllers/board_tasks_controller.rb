class BoardTasksController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [ :update_position ]

  def update_position
    task = Task.find(params[:id])
    column = Column.find(params[:column_id])
    board = column.board

    # Determinar si es la última columna del board (la de mayor posición)
    # Usar reorder para anular el default_scope de la asociación
    last_column = board.columns.reorder(position: :desc).first
    is_last_column = column.id == last_column.id

    # Actualizar tarea con nueva columna, posición y estado done
    # Si se mueve a la última columna: done = true
    # Si se mueve a cualquier otra columna: done = false
    task.update(
      column: column,
      position: params[:position].to_i,
      done: is_last_column
    )

    # Reordenar las demás tareas en la columna
    column.tasks.where.not(id: task.id).order(:position).each_with_index do |t, index|
      new_position = index >= params[:position].to_i ? index + 1 : index
      t.update_column(:position, new_position) if t.position != new_position
    end

    render json: { is_completed: task.done }
  end

  def add_to_board
    task = Task.find(params[:id])
    project = task.todo.project

    # Obtener el primer tablero del proyecto
    board = project.boards.order(created_at: :asc).first

    if board.nil?
      respond_to do |format|
        format.html { redirect_to project_todo_task_path(project, task.todo, task), alert: "No hay tableros disponibles en este proyecto." }
        format.json { render json: { success: false, error: "No boards available" }, status: :unprocessable_entity }
      end
      return
    end

    # Obtener la primera columna del tablero
    column = board.columns.order(position: :asc).first

    if column.nil?
      respond_to do |format|
        format.html { redirect_to project_todo_task_path(project, task.todo, task), alert: "El tablero no tiene columnas disponibles." }
        format.json { render json: { success: false, error: "No columns available" }, status: :unprocessable_entity }
      end
      return
    end

    # Determinar si es la última columna del board
    last_column = board.columns.reorder(position: :desc).first
    is_last_column = column.id == last_column.id

    # Obtener la última posición en la columna
    last_position = column.tasks.maximum(:position) || -1

    # Agregar tarea a la columna
    task.update(
      column: column,
      position: last_position + 1,
      done: is_last_column
    )

    respond_to do |format|
      format.html { redirect_to project_todo_task_path(project, task.todo, task), notice: "Tarea agregada al tablero #{board.title}." }
      format.json { render json: { success: true, column_id: column.id, board_title: board.title, column_title: column.title } }
    end
  end

  def remove_from_board
    task = Task.find(params[:id])
    project = task.todo.project
    board_id = params[:board_id]

    task.update(column: nil, position: 0)

    # Mantener los query params originales de la request
    redirect_url = project_board_path(project, board_id, request.query_parameters)

    respond_to do |format|
      format.turbo_stream { redirect_to redirect_url, status: :see_other }
      format.html { redirect_to redirect_url, notice: "Tarea removida del tablero." }
      format.json { render json: { success: true } }
    end
  end
end
