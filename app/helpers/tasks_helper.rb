module TasksHelper
  TASK_STATUS_LABELS = {
    "pending" => "Pendiente",
    "in_progress" => "En progreso",
    "done" => "Hecha"
  }.freeze

  def task_status_label(status)
    TASK_STATUS_LABELS.fetch(status.to_s, status.to_s.humanize)
  end

  def task_due_label(task)
    label = l(task.due_date.to_date, format: :long)
    task.due_date_has_time? ? "#{label} · #{task.due_date.strftime('%H:%M')}" : label
  end

  # Clases del pill de vencimiento según cercanía de la fecha.
  def task_due_pill_classes(task)
    days = (task.due_date.to_date - Date.current).to_i

    if task.completed? || days > 3
      "bg-paper text-ink/70 border-ink"
    elsif days < 0
      "bg-danger-light text-danger border-danger/40"
    else
      "bg-warning-light text-warning border-warning/40"
    end
  end

  def task_google_calendar_url(task, task_url)
    due = task.due_date
    duration = task.custom_field_values.find { |v| v.project_custom_field.key == "duration" }&.value.to_f

    dates = if task.due_date_has_time?
      ending = due.utc + (duration.positive? ? duration.hours : 1.hour)
      "#{due.utc.strftime('%Y%m%dT%H%M%SZ')}/#{ending.strftime('%Y%m%dT%H%M%SZ')}"
    else
      "#{due.to_date.strftime('%Y%m%d')}/#{(due.to_date + 1).strftime('%Y%m%d')}"
    end

    "https://calendar.google.com/calendar/render?" + {
      action: "TEMPLATE",
      text: task.title,
      dates: dates,
      details: "#{task.title}\n#{task_url}"
    }.to_query
  end
end
