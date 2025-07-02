class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_current_user
  helper_method :current_user

  private

  def set_current_user
    @current_user = Current.session&.user
  end

  def current_user
      @current_user = Current.session&.user
      if @current_user.nil?
        nil
      else
        @current_user
      end
  end
end
