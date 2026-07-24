class TaskDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task

  def create
    @document = @project.documents.not_archived.visible_to(current_user).find(params[:document_id])
    @task_document = @task.task_documents.new(document: @document)

    if @task_document.save
      render json: {
        success: true,
        document: document_json(@document)
      }
    else
      render json: { success: false, error: @task_document.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    @task_document = @task.task_documents.find_by(document_id: params[:id])

    if @task_document&.destroy
      respond_to do |format|
        format.turbo_stream { redirect_to project_todo_task_path(@task.todo.project, @task.todo, @task), status: :see_other }
        format.html { redirect_to project_todo_task_path(@task.todo.project, @task.todo, @task), notice: "Documento desenlazado correctamente" }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to project_todo_task_path(@task.todo.project, @task.todo, @task), status: :see_other }
        format.html { redirect_to project_todo_task_path(@task.todo.project, @task.todo, @task), alert: "No se pudo desenlazar el documento" }
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end

  def search
    query = params[:query].to_s.downcase

    linked_document_ids = @task.documents.pluck(:id)

    documents = @project.documents.not_archived.visible_to(current_user)
      .where.not(id: linked_document_ids)
      .where("LOWER(name) LIKE ?", "%#{query}%")
      .limit(8)

    render json: documents.map { |d| document_json(d) }
  end

  private

  def document_json(document)
    {
      id: document.id,
      name: document.name,
      url: document_path(document)
    }
  end

  def set_task
    @project = Project.for_user(current_user).find(params[:project_id])
    @todo = @project.todos.find(params[:todo_id])
    @task = @todo.tasks.find(params[:task_id])
  end
end
