class AnnouncementsController < ApplicationController
  before_action :set_project
  def index
    @announcements = @project.announcements
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

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def announcement_params
    params.require(:announcement).permit(:content)
  end
end
