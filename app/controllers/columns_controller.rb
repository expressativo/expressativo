class ColumnsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_board
  before_action :set_column, only: [ :update, :destroy, :update_position ]

  def create
    @column = @board.columns.new(column_params)
    @column.kind ||= "custom"

    done_column = @board.columns.find_by(kind: "done")
    @column.position =
      if done_column
        done_column.position
      else
        @board.columns.maximum(:position).to_i + 1
      end

    if @column.save
      render json: {
        success: true,
        column: {
          id: @column.id,
          title: @column.title,
          position: @column.position,
          kind: @column.kind
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
    if @column.done?
      return render json: { success: false, errors: [ "La columna 'Done' no se puede eliminar" ] }, status: :unprocessable_entity
    end

    @column.destroy
    render json: { success: true }
  end

  def update_position
    if @column.done?
      return render json: { success: false, error: "La columna 'Done' no puede moverse" }, status: :unprocessable_entity
    end

    new_position = params[:position].to_i
    old_position = @column.position

    done_column = @board.columns.where.not(id: @column.id).find_by(kind: "done")
    if done_column
      new_position = [ new_position, done_column.position - 1 ].min
    end

    if new_position < old_position
      @board.columns.where("position >= ? AND position < ?", new_position, old_position)
                    .where.not(id: @column.id)
                    .update_all("position = position + 1")
    elsif new_position > old_position
      @board.columns.where("position > ? AND position <= ?", old_position, new_position)
                    .where.not(id: @column.id)
                    .update_all("position = position - 1")
    end

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
