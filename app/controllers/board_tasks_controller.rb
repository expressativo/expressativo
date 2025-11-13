class BoardTasksController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:update_position]

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

  def remove_from_board
    task = Task.find(params[:id])
    task.update(column: nil, position: 0)
    
    redirect_to project_board_path(task.todo.project, params[:board_id]), 
                notice: "Tarea removida del tablero."
  end
end
