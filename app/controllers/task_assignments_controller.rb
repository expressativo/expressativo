class TaskAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task

  def create
    @user = User.find(params[:user_id])
    @assignment = @task.task_assignments.new(user: @user)
    
    if @assignment.save
      render json: { 
        success: true, 
        user: { 
          id: @user.id, 
          name: @user.full_name,
          email: @user.email
        } 
      }
    else
      render json: { success: false, error: @assignment.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    @assignment = @task.task_assignments.find_by(user_id: params[:id])
    @todo = @task.todo
    @project = @todo.project
    
    if @assignment&.destroy
      redirect_to project_todo_task_path(@project, @todo, @task), notice: "Usuario desasignado correctamente."
    else
      redirect_to project_todo_task_path(@project, @todo, @task), alert: "Error al desasignar usuario."
    end
  end

  def search
    project = @task.todo.project
    query = params[:query].to_s.downcase
    
    # Buscar usuarios del proyecto que no estén ya asignados
    assigned_user_ids = @task.assigned_users.pluck(:id)
    
    users = project.users
      .where.not(id: assigned_user_ids)
      .where("LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?", 
             "%#{query}%", "%#{query}%", "%#{query}%")
      .limit(5)
    
    render json: users.map { |u| { id: u.id, name: u.full_name, email: u.email } }
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end
end
