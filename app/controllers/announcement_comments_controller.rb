class AnnouncementCommentsController < ApplicationController
  before_action :set_context

  def new
    @announcement_comment = AnnouncementComment.new
  end

  def edit
    @announcement_comment = AnnouncementComment.find(params[:id])
  end
  def update
  end
  def create
     @announcement_comment = AnnouncementComment.new(
      content: params[:announcement_comment][:content],
      user: current_user,
      announcement: @announcement
     )
    if @announcement_comment.save
      redirect_to project_announcement_path(@project, @announcement), notice: "Anuncio creado correctamente"
    else
      render :new
    end
  end

  private

  def announcement_comments_params
    params.require(:announcement_comment).permit(:content)
  end

  def set_context
    @project = Project.find(params[:project_id])
    @announcement = @project.announcements.find(params[:announcement_id])
  end
end
