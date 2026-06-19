class TaskCustomFieldValuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context
  before_action -> { require_non_viewer!(@project) }

  def update
    field = @project.custom_fields.find(params[:project_custom_field_id])
    value_record = @task.custom_field_values.find_or_initialize_by(project_custom_field: field)

    value = params.dig(:task_custom_field_value, :value).to_s.strip

    if value.blank?
      value_record.destroy if value_record.persisted?
    else
      value_record.value = value
      value_record.save
    end

    redirect_to project_todo_task_path(@project, @todo, @task)
  end

  private

  def set_context
    @project = Project.for_user(current_user).find(params[:project_id])
    @todo = @project.todos.find(params[:todo_id])
    @task = @todo.tasks.find(params[:task_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "El recurso solicitado no existe o no tienes acceso."
  end
end
