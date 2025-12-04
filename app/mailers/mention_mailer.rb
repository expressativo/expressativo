class MentionMailer < ApplicationMailer
  default from: "notificaciones@expressativo.com"

  def mention_notification(user, comment)
    @user = user
    @comment = comment
    @task = comment.task
    @project = @task.todo.project
    @mentioned_by = comment.user

    mail(
      to: user.email,
      subject: "#{@mentioned_by.full_name || @mentioned_by.email} te mencionó en un comentario"
    )
  end
end
