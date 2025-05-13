class TodosController < ApplicationController
    before_action :set_project


    def index
      @todos = @project.todos
    end

    private
    def set_project
      @project = Project.find(params[:project_id])
    end
end
