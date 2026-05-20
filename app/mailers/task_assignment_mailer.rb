class TaskAssignmentMailer < ApplicationMailer
  default from: "notificaciones@expressativo.com"

  def assignment_notification(task_assignment)
    @task_assignment = task_assignment
    @task = task_assignment.task
    @project = @task.todo.project
    @assigned_by = @task.created_by

    mail(
      to: task_assignment.user.email,
      subject: "Se te ha asignado una nueva tarea en #{@project.name}"
    )
  end
end