module ApiAuthenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_user!
  end

  private

  def authenticate_api_user!
    if current_api_user.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def current_api_user
    return @current_api_user if defined?(@current_api_user)

    token_value = extract_bearer_token
    return @current_api_user = nil if token_value.blank?

    access_token = CliAccessToken.authenticate(token_value)
    return @current_api_user = nil if access_token.nil?

    Current.user = access_token.user if defined?(Current)
    @current_api_user = access_token.user
  end

  def extract_bearer_token
    header = request.headers["Authorization"].to_s
    return nil unless header.match?(/\ABearer\s+/i)

    header.split(/\s+/, 2).last
  end
end
