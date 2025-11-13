class ColumnsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_board
  before_action :set_column, only: [:update, :destroy]

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
