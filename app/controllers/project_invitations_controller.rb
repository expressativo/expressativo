class ProjectInvitationsController < ApplicationController
  before_action :set_project_by_token, only: [:show, :accept]
  before_action :authenticate_user!, only: [:accept]

  def show
    # Mostrar página de invitación
    if user_signed_in?
      # Si ya está autenticado, verificar si ya es miembro
      if @project.project_users.exists?(user_id: current_user.id)
        flash[:notice] = "Ya eres miembro de este proyecto."
        redirect_to project_path(@project)
      else
        # Mostrar página de confirmación
        render :show
      end
    else
      # Redirigir a registro/login con el token guardado en sesión
      session[:invitation_token] = params[:token]
      flash[:notice] = "Por favor, inicia sesión o regístrate para unirte al proyecto."
      redirect_to new_user_session_path
    end
  end

  def accept
    if @project.project_users.exists?(user_id: current_user.id)
      flash[:alert] = "Ya eres miembro de este proyecto."
      redirect_to project_path(@project)
      return
    end

    @project_user = @project.project_users.new(user: current_user, role: "member")

    if @project_user.save
      flash[:notice] = "Te has unido al proyecto exitosamente."
      redirect_to project_path(@project)
    else
      flash[:alert] = "Hubo un error al unirte al proyecto."
      redirect_to root_path
    end
  end

  def regenerate
    @project = Project.for_user(current_user).find(params[:project_id])
    
    if @project.owner == current_user
      @project.regenerate_invitation_token!
      flash[:notice] = "Link de invitación regenerado exitosamente."
    else
      flash[:alert] = "Solo el propietario puede regenerar el link de invitación."
    end
    
    redirect_to project_members_path(@project)
  end

  private

  def set_project_by_token
    @project = Project.find_by(invitation_token: params[:token])
    
    unless @project
      flash[:alert] = "Link de invitación inválido o expirado."
      redirect_to root_path
    end
  end
end
