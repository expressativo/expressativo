class TimelinesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project

  def show
    @activities = @project.activities
                          .includes(:user, :trackable)
                          .order(created_at: :desc)
                          .limit(100)

    @activities_by_date = @activities.group_by { |activity| activity.created_at.to_date }
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end
end
