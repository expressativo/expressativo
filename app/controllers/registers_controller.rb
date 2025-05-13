class RegistersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end



  def create
    @user = User.new(user_params)
    Rails.logger.debug @user.inspect
    if @user.save
      start_new_session_for @user
      redirect_to projects_path, notice: "Welcome!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:email_address, :password, :password_confirmation)
  end
end
