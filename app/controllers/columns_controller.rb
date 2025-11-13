class ColumnsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_board
  before_action :set_column, only: [:update, :destroy, :update_position]

  def create
    @column = @board.columns.new(column_params)
    @column.position = @board.columns.maximum(:position).to_i + 1

    if @column.save
      render json: { 
        success: true, 
        column: {
          id: @column.id,
          title: @column.title,
          position: @column.position
        }
      }
    else
      render json: { success: false, errors: @column.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @column.update(column_params)
      render json: { success: true, title: @column.title }
    else
      render json: { success: false, errors: @column.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @column.destroy
    render json: { success: true }
  end

  def update_position
    new_position = params[:position].to_i
    old_position = @column.position

    # Reordenar columnas
    if new_position < old_position
      # Mover hacia la izquierda: incrementar posición de columnas entre new y old
      @board.columns.where("position >= ? AND position < ?", new_position, old_position)
                    .update_all("position = position + 1")
    elsif new_position > old_position
      # Mover hacia la derecha: decrementar posición de columnas entre old y new
      @board.columns.where("position > ? AND position <= ?", old_position, new_position)
                    .update_all("position = position - 1")
    end

    # Actualizar posición de la columna movida
    @column.update(position: new_position)

    render json: { success: true }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_board
    @board = @project.boards.find(params[:board_id])
  end

  def set_column
    @column = @board.columns.find(params[:id])
  end

  def column_params
    params.require(:column).permit(:title)
  end
end
