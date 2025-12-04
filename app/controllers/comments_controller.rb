class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context
  before_action :set_comment, only: [ :edit, :update, :destroy ]
  before_action :authorize_user!, only: [ :edit, :update, :destroy ]

  def show
    @comment = @task.comments.find(params[:id])

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    if @comment.update(comment_params)
      respond_to do |format|
        format.html { redirect_to project_todo_task_path(@project, @todo, @task), notice: "Comentario actualizado correctamente." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @comment.destroy
    redirect_to project_todo_task_path(@project, @todo, @task), notice: "Comentario eliminado correctamente."
  end

  private

  def set_context
    @project = Project.find(params[:project_id])
    @todo = Todo.find(params[:todo_id])
    @task = Task.find(params[:task_id])
  end

  def set_comment
    @comment = @task.comments.find(params[:id])
  end

  def authorize_user!
    unless @comment.user == current_user
      redirect_to project_todo_task_path(@project, @todo, @task), alert: "No tienes permiso para realizar esta acción."
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
