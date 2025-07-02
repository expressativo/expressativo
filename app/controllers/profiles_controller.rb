class ProfilesController < ApplicationController
  def index
    @user = current_user
  end
  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user  = current_user
    if @user.update(user_params)
      redirect_to profiles_path, notice: "Perfil actualizado correctamente."
    else
      render :index
    end
  end

  private

  def user_params
    params.permit(:email_address, :password, :password_confirmation, :first_name, :last_name)
  end
end
