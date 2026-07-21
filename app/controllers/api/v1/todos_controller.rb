class Api::V1::TodosController < Api::V1::BaseController
  before_action :set_project

  # GET /api/v1/projects/:project_id/todos
  def index
    @todos = @project.todos.active.order(:name)
  end

  private

  def set_project
    @project = Project.for_user(current_api_user).find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end
end
