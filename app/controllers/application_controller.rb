class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_current_user
  before_action :process_pending_invitation

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :avatar])
  end

  def set_current_user
    Current.user = current_user if user_signed_in?
  end

  def process_pending_invitation
    return unless user_signed_in?
    return unless session[:invitation_token].present?

    token = session.delete(:invitation_token)
    redirect_to project_invitation_path(token: token)
  end
end
