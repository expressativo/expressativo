class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications
                                 .includes(:notifiable)
                                 .recent
                                 .page(params[:page])
                                 .per(20)
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!

    redirect_to notification_path(notification)
  end

  def mark_all_as_read
    Notification.mark_all_as_read(current_user)
    redirect_to notifications_path, notice: "Todas las notificaciones marcadas como leídas"
  end

  def show
    @notification = current_user.notifications.includes(notifiable: { task: { todo: :project } }).find(params[:id])
    @notification.mark_as_read!

    # Redirigir según el tipo de notificación
    case @notification.notifiable_type
    when "Comment"
      comment = @notification.notifiable
      redirect_to project_todo_task_path(
        comment.task.todo.project,
        comment.task.todo,
        comment.task,
        anchor: "comment_#{comment.id}"
      )
    else
      redirect_to notifications_path
    end
  end

  def unread_count
    render json: { count: current_user.notifications.unread.count }
  end
end
