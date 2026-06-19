class ProjectMembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action -> { require_non_viewer!(@project) }

  def index
    @members = @project.project_users.includes(:user).where(role: %w[member viewer])
    @owner = @project.owner
  end

  def new
    @project_user = @project.project_users.new
  end

  def create
    user = User.find_by(email: params[:email])

    if user.nil?
      flash[:alert] = "No se encontró un usuario con ese email."
      redirect_to new_project_member_path(@project) and return
    end

    if @project.project_users.exists?(user_id: user.id)
      flash[:alert] = "Este usuario ya es miembro del proyecto."
      redirect_to new_project_member_path(@project) and return
    end

    role = params[:role].presence_in(%w[member viewer]) || "member"
    @project_user = @project.project_users.new(user: user, role: role)

    if @project_user.save
      flash[:notice] = "#{role == 'viewer' ? 'Observador' : 'Miembro'} agregado exitosamente."
      redirect_to project_members_path(@project)
    else
      flash[:alert] = "Hubo un error al agregar el miembro."
      redirect_to new_project_member_path(@project)
    end
  end

  def update
    @project_user = @project.project_users.find(params[:id])

    if @project_user.role == "owner"
      flash[:alert] = "No puedes cambiar el rol del propietario."
      redirect_to project_members_path(@project) and return
    end

    new_role = params[:project_user][:role].presence_in(%w[member viewer])

    if new_role && @project_user.update(role: new_role)
      flash[:notice] = "Rol actualizado correctamente."
    else
      flash[:alert] = "No se pudo actualizar el rol."
    end

    redirect_to project_members_path(@project)
  end

  def destroy
    @project_user = @project.project_users.find(params[:id])

    if @project_user.role == "owner"
      flash[:alert] = "No puedes eliminar al propietario del proyecto."
      redirect_to project_members_path(@project) and return
    end

    @project_user.destroy
    flash[:notice] = "Miembro eliminado exitosamente."
    redirect_to project_members_path(@project)
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end
end
