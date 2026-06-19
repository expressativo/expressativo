class PublicTasksController < ApplicationController
  layout "public"

  def show
    @task = Task.where.not(public_token: nil).find_by!(public_token: params[:public_token])
    @todo = @task.todo
    @project = @todo.project
  end
end
