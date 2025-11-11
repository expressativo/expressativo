class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    
    if update_user
      redirect_to profile_path, notice: "Perfil actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def update_user
    if user_params[:password].present?
      @user.update(user_params)
    else
      # Si no se proporciona contraseña, actualizar sin ella
      @user.update_without_password(user_params.except(:password, :password_confirmation))
    end
  end

  def user_params
    params.require(:user).permit(
      :first_name, 
      :last_name, 
      :email, 
      :avatar,
      :password,
      :password_confirmation,
      :current_password
    )
  end
end
