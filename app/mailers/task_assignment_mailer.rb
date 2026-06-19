class TaskAssignmentMailer < ApplicationMailer
  def assignment_notification(task_assignment)
    @task_assignment = task_assignment
    @task = task_assignment.task
    @project = @task&.todo&.project
    @assigned_by = @task&.created_by

    return if @task.nil? || @project.nil? || task_assignment.user&.email.blank?

    @task_url = project_todo_task_url(@project, @task.todo, @task)

    if @task.due_date.present?
      due = @task.due_date.to_date
      @gcal_url = "https://calendar.google.com/calendar/render?" + {
        action:  "TEMPLATE",
        text:    @task.title,
        dates:   "#{due.strftime('%Y%m%d')}/#{(due + 1).strftime('%Y%m%d')}",
        details: "Tarea de Tivo: #{@task_url}"
      }.to_query

      ics = @task.to_ics(task_url: @task_url, host: Rails.application.routes.default_url_options[:host] || "tivo.app")
      attachments["tarea-#{@task.id}.ics"] = { mime_type: "text/calendar", content: ics }
    end

    mail(
      to: task_assignment.user.email,
      subject: "[#{@project.title.to_s.upcase}] - Te han asignado una tarea"
    )
  end
end