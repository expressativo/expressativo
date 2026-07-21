class Api::V1::MeController < Api::V1::BaseController
  # GET /api/v1/me
  def show
    render json: {
      id: current_api_user.id,
      email: current_api_user.email,
      first_name: current_api_user.first_name,
      last_name: current_api_user.last_name
    }
  end
end
