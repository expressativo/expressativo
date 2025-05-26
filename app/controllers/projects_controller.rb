class ProjectsController < ApplicationController
  before_action :require_authentication

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    @project.user = current_user
    if @project.save
      redirect_to projects_path, notice: "Project was successfully created."
    else
      Rails.logger.debug(@project.errors.full_messages)
      render :new
    end
  end

  def index
    @projects = Project.all
  end

  def show
    @project = Project.find(params[:id])
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    if @project.update(project_params)
      redirect_to projects_path, notice: "Project was successfully updated."
    else
      render :edit
    end
  end
  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully destroyed."
  end

  private
  def project_params
    params.require(:project).permit(:title, :description)
  end
end
