class MentionMailer < ApplicationMailer
  def mention_notification(user, comment)
    @user = user
    @comment = comment
    @task = comment&.task
    @project = @task&.todo&.project
    @mentioned_by = comment&.user

    return if @task.nil? || @project.nil? || @mentioned_by.nil? || user&.email.blank?

    mail(
      to: user.email,
      subject: "#{@mentioned_by.full_name || @mentioned_by.email} te mencionó en un comentario"
    )
  end
end
