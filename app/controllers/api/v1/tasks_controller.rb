class Api::V1::TasksController < Api::V1::BaseController
  before_action :set_todo, only: [ :index, :create ]
  before_action :set_task, only: [ :show, :update, :destroy ]

  # GET /api/v1/todos/:todo_id/tasks?status=pending|in_progress|done
  def index
    @tasks = @todo.tasks.list_ordered
    @tasks = @tasks.where(status: params[:status]) if params[:status].present? && Task::STATUSES.include?(params[:status])
  end

  # POST /api/v1/todos/:todo_id/tasks
  def create
    @task = @todo.tasks.new(task_params.merge(created_by: current_api_user))
    if @task.save
      render :show, status: :created
    else
      render json: { error: "validation_error", message: @task.errors.full_messages.to_sentence },
             status: :unprocessable_entity
    end
  end

  # GET /api/v1/tasks/:id
  def show
  end

  # PATCH /api/v1/tasks/:id
  def update
    if @task.update(task_params)
      render :show
    else
      render json: { error: "validation_error", message: @task.errors.full_messages.to_sentence },
             status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/tasks/:id
  def destroy
    @task.destroy!
    render json: { ok: true }
  end

  private

  def accessible_project_ids
    @accessible_project_ids ||= Project.for_user(current_api_user).pluck(:id)
  end

  def set_todo
    @todo = Todo.joins(:project).where(projects: { id: accessible_project_ids }).find(params[:todo_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  def set_task
    @task = Task.joins(todo: :project).where(projects: { id: accessible_project_ids }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  def task_params
    permitted = params.require(:task).permit(:title, :status, :completed, :notes, :due_date)
    if permitted.key?(:notes)
      plain = permitted[:notes].to_s
      permitted[:notes] = plain.present? ? "<div>#{plain}</div>" : ""
    end
    permitted[:due_date] = nil if permitted.key?(:due_date) && permitted[:due_date].blank?
    permitted
  end
end
