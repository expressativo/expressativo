class AnnouncementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  def index
    @announcements = @project.announcements.order(created_at: :desc)
  end

  def new
    @announcement = @project.announcements.build
  end

  def create
    @announcement = @project.announcements.build(announcement_params)
    if @announcement.save
      redirect_to project_announcements_path(@project), notice: "Anuncio creado correctamente"
    else
      render :new
    end
  end

  def edit
    @announcement = @project.announcements.find(params[:id])
  end

  def update
    @announcement = @project.announcements.find(params[:id])
    if @announcement.update(announcement_params)
      redirect_to project_announcements_path(@project), notice: "Anuncio actualizado correctamente"
    else
      render :edit
    end
  end

  def show
    @announcement = @project.announcements.find(params[:id])
    @comments = @announcement.announcement_comments.includes(:user).order(created_at: :desc)
  end

  def destroy
    @announcement = @project.announcements.find(params[:id])
    @announcement.destroy
    redirect_to project_announcements_path(@project), notice: "Anuncio eliminado correctamente"
  end


  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def announcement_params
    params.require(:announcement).permit(:content)
  end
end
