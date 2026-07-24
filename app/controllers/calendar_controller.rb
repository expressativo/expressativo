class CalendarController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action -> { require_non_viewer!(@project) }

  def show
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month

    @month = 1 if @month < 1
    @month = 12 if @month > 12

    @date = Date.new(@year, @month, 1)

    tasks = Task.joins(:todo)
                .where(todos: { project_id: @project.id })
                .where(due_date: @date.beginning_of_month.beginning_of_day..@date.end_of_month.end_of_day)
                .includes(:todo, :documents)
                .order(:due_date)

    @tasks_by_date = tasks.group_by { |task| task.due_date.to_date }
  end

  def update_task_date
    task = Task.joins(:todo).where(todos: { project_id: @project.id }).find(params[:task_id])
    new_date = Date.parse(params[:new_date])

    # Preservar la hora si la tarea ya tenía una definida
    new_due_date = task.due_date_has_time? ? new_date.to_time + task.due_date.seconds_since_midnight : new_date

    if task.update(due_date: new_due_date)
      render json: { success: true }
    else
      render json: { success: false, errors: task.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ArgumentError
    render json: { success: false, errors: [ "Fecha inválida" ] }, status: :unprocessable_entity
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end
end
