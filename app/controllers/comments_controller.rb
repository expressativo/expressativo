class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_commentable
  before_action :set_comment, only: [ :edit, :update, :destroy ]
  before_action :authorize_user!, only: [ :edit, :update, :destroy ]

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    if @comment.update(comment_params)
      respond_to do |format|
        format.html { redirect_to comment_back_path(@commentable), notice: "Comentario actualizado correctamente.", status: :see_other }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @comment.destroy
    redirect_to comment_back_path(@commentable), notice: "Comentario eliminado correctamente.", status: :see_other
  end

  private

  def set_commentable
    if params[:project_id].present? && params[:todo_id].present? && params[:task_id].present?
      set_task_context
    elsif params[:document_id].present?
      set_document_context
    else
      redirect_to root_path, alert: "Contexto inválido para el comentario.", status: :see_other
    end
  end

  def set_task_context
    @project = Project.for_user(current_user).find(params[:project_id])
    @todo = @project.todos.find(params[:todo_id])
    @task = @todo.tasks.find(params[:task_id])
    @commentable = @task
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "El recurso solicitado no existe o no tienes acceso.", status: :see_other
  end

  def set_document_context
    @document = Document.joins(project: :project_users)
                        .where(project_users: { user_id: current_user.id })
                        .visible_to(current_user)
                        .find(params[:document_id])
    @project = @document.project
    @commentable = @document
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "El documento solicitado no existe o no tienes acceso.", status: :see_other
  end

  def set_comment
    @comment = @commentable.comments.find(params[:id])
  end

  def authorize_user!
    return if @comment.user == current_user

    redirect_to comment_back_path(@commentable), alert: "No tienes permiso para realizar esta acción.", status: :see_other
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
