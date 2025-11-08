class BoardTasksController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:update_position]

  def update_position
    task = Task.find(params[:id])
    column = Column.find(params[:column_id])
    
    task.update(
      column: column,
      position: params[:position].to_i
    )
    
    # Reordenar las demás tareas en la columna
    column.tasks.where.not(id: task.id).order(:position).each_with_index do |t, index|
      new_position = index >= params[:position].to_i ? index + 1 : index
      t.update_column(:position, new_position) if t.position != new_position
    end

    head :ok
  end

  def remove_from_board
    task = Task.find(params[:id])
    task.update(column: nil, position: 0)
    
    redirect_to project_board_path(task.todo.project, params[:board_id]), 
                notice: "Tarea removida del tablero."
  end
end
