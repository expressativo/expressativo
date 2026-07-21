class Api::V1::ProjectsController < Api::V1::BaseController
  before_action :set_project, only: [ :show ]

  # GET /api/v1/projects
  def index
    @projects = Project.for_user(current_api_user)
                       .active
                       .includes(:todos)
                       .order(updated_at: :desc)
  end

  # GET /api/v1/projects/:id
  def show
  end

  private

  def set_project
    @project = Project.for_user(current_api_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end
end
