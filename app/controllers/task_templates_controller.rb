class TaskTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action -> { require_non_viewer!(@project) }
  before_action :set_template, only: %i[edit update destroy]

  def index
    @templates = @project.task_templates.order(:name)
    @template = TaskTemplate.new
  end

  def new
    @template = TaskTemplate.new
  end

  def create
    @template = @project.task_templates.new(template_params)

    if @template.save
      redirect_to project_task_templates_path(@project), notice: "Template creado."
    else
      @templates = @project.task_templates.order(:name)
      flash.now[:alert] = @template.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      redirect_to project_task_templates_path(@project), notice: "Template actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to project_task_templates_path(@project), notice: "Template eliminado."
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end

  def set_template
    @template = @project.task_templates.find(params[:id])
  end

  def template_params
    params.require(:task_template).permit(:name, :title, :notes)
  end
end
