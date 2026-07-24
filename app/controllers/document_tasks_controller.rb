class DocumentTasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document

  def create
    @task = Task.joins(:todo).where(todos: { project_id: @project.id }).find(params[:task_id])
    @task_document = @document.task_documents.new(task: @task)

    if @task_document.save
      render json: {
        success: true,
        task: task_json(@task)
      }
    else
      render json: { success: false, error: @task_document.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    @task_document = @document.task_documents.find_by(task_id: params[:id])

    if @task_document&.destroy
      respond_to do |format|
        format.turbo_stream { redirect_to document_path(@document), status: :see_other }
        format.html { redirect_to document_path(@document), notice: "Tarea desenlazada correctamente" }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to document_path(@document), status: :see_other }
        format.html { redirect_to document_path(@document), alert: "No se pudo desenlazar la tarea" }
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end

  def search
    query = params[:query].to_s.downcase

    linked_task_ids = @document.tasks.pluck(:id)

    tasks = Task.joins(:todo)
      .where(todos: { project_id: @project.id, archived: false })
      .where.not(id: linked_task_ids)
      .where("LOWER(tasks.title) LIKE ?", "%#{query}%")
      .limit(8)

    render json: tasks.map { |t| task_json(t) }
  end

  private

  def task_json(task)
    {
      id: task.id,
      title: task.title,
      todo_name: task.todo.name,
      url: project_todo_task_path(@project, task.todo, task)
    }
  end

  def set_document
    @document = Document.find(params[:document_id])
    @project = Project.for_user(current_user).find(@document.project_id)
  end
end
