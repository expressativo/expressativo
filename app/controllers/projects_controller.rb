class ProjectsController < ApplicationController
  before_action :authenticate_user!
  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      @project.project_users.create!(user: current_user, role: "owner")
      flash[:notice] = "Project was successfully created."
      redirect_to projects_path
    else
      Rails.logger.debug(@project.errors.full_messages)
      render :new
    end
  end

  def index
    @projects = Project.for_user(current_user).active
                       .includes(:todos, :boards, :users, project_users: :user)
                       .order(updated_at: :desc)
  end

  def archived
    @projects = Project.for_user(current_user).archived.includes(:project_users, :users)
    render :archived
  end

  def show
    @project = Project.for_user(current_user)
                      .includes(boards: [], publications: :task, project_users: :user)
                      .find(params[:id])

    project_tasks = Task.joins(:todo).where(todos: { project_id: @project.id })

    @todos_count       = @project.todos.count
    @tasks_total       = project_tasks.count
    @tasks_completed   = project_tasks.where(done: true).count
    @tasks_pending     = @tasks_total - @tasks_completed
    @completion_pct    = @tasks_total.zero? ? 0 : ((@tasks_completed.to_f / @tasks_total) * 100).round
    @documents_count   = @project.documents.not_archived.count
    @boards_count      = @project.boards.count

    @upcoming_tasks = project_tasks
                       .where(done: false)
                       .where.not(due_date: nil)
                       .where("due_date >= ?", Time.current.beginning_of_day)
                       .includes(:assigned_users, todo: {})
                       .order(:due_date)
                       .limit(5)

    @recent_activities = Activity.for_project(@project)
                                 .recent
                                 .includes(:user, :trackable)
                                 .limit(6)

    @recent_documents     = @project.documents.not_archived.order(updated_at: :desc).limit(4)
    @recent_announcements = @project.announcements.order(created_at: :desc).limit(3)
  end

  def edit
    @project = Project.for_user(current_user).find(params[:id])
  end

  def update
    @project = Project.for_user(current_user).find(params[:id])
    if @project.update(project_params)
      redirect_to project_path(@project), notice: "Actualizado correctamente."
    else
      render :edit
    end
  end
  def destroy
    @project = Project.for_user(current_user).find(params[:id])
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully destroyed."
  end

  def archive
    @project = Project.for_user(current_user).find(params[:id])
    @project.update(archived: true)
    redirect_to projects_path, notice: "Proyecto archivado correctamente."
  end

  def unarchive
    @project = Project.for_user(current_user).find(params[:id])
    @project.update(archived: false)
    redirect_to projects_path, notice: "Proyecto desarchivado correctamente."
  end

  private
  def project_params
    params.require(:project).permit(:title, :description, :has_calendar)
  end
end
