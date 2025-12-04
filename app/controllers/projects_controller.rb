class ProjectsController < ApplicationController
  before_action :authenticate_user!
  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      @project.project_users.create!(user: current_user, role: "owner")
      flash[:notice] = "Project was successfully created."
      redirect_to projects_path
    else
      Rails.logger.debug(@project.errors.full_messages)
      render :new
    end
  end

  def index
    @projects = Project.for_user(current_user).active.includes(:project_users, :users)
  end

  def archived
    @projects = Project.for_user(current_user).archived.includes(:project_users, :users)
    render :archived
  end

  def show
    @project = Project.for_user(current_user)
                      .includes(boards: [], publications: :task)
                      .find(params[:id])
  end

  def edit
    @project = Project.for_user(current_user).find(params[:id])
  end

  def update
    @project = Project.for_user(current_user).find(params[:id])
    if @project.update(project_params)
      redirect_to project_path(@project), notice: "Project was successfully updated."
    else
      render :edit
    end
  end
  def destroy
    @project = Project.for_user(current_user).find(params[:id])
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully destroyed."
  end

  def archive
    @project = Project.for_user(current_user).find(params[:id])
    @project.update(archived: true)
    redirect_to projects_path, notice: "Proyecto archivado correctamente."
  end

  def unarchive
    @project = Project.for_user(current_user).find(params[:id])
    @project.update(archived: false)
    redirect_to projects_path, notice: "Proyecto desarchivado correctamente."
  end

  private
  def project_params
    params.require(:project).permit(:title, :description)
  end
end
