class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
   def current_user
      @current_user = Current.session&.user
      if @current_user.nil?
        Rails.logger.debug(">>>> No current user found")
        nil
      else
        Rails.logger.debug(">>>> Current user: #{@current_user.inspect}")
        @current_user
      end
   end
end
