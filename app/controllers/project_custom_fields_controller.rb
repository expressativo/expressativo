class ProjectCustomFieldsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action -> { require_non_viewer!(@project) }

  def index
    @custom_fields = @project.custom_fields.order(:position).to_a
    @custom_field = ProjectCustomField.new(project: @project)
  end

  def create
    @custom_field = @project.custom_fields.new(custom_field_params)

    if @custom_field.save
      redirect_to project_custom_fields_path(@project), notice: "Campo personalizado creado."
    else
      @custom_fields = @project.custom_fields.order(:position).to_a
      flash.now[:alert] = @custom_field.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_field = @project.custom_fields.find(params[:id])
    @custom_field.destroy
    redirect_to project_custom_fields_path(@project), notice: "Campo eliminado."
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end

  def custom_field_params
    raw = params.require(:project_custom_field).permit(:name, :field_type, :options_raw, :key)
    options_raw = raw.delete(:options_raw)

    if raw[:field_type] == "select" && options_raw.present?
      raw[:options] = options_raw.split(",").map(&:strip).reject(&:blank?)
    end

    raw
  end
end
