module Projects
  class SettingsController < ApplicationController
    before_action :set_project

    def index
    end

    def update
      @project.update(project_params)
      redirect_to project_settings_path(@project)
    end

    private

    def project_params
      params.require(:project).permit(:has_calendar)
    end

    def set_project
      @project = Project.find(params[:project_id])
    end
  end
end
