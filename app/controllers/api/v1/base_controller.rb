class Api::V1::BaseController < ApplicationController
  include ApiAuthenticable

  protect_from_forgery with: :null_session
  skip_before_action :configure_permitted_parameters
  skip_before_action :set_current_user
  skip_before_action :process_pending_invitation
end
