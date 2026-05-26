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
      subject: "[#{@project.title.to_s.upcase}] - Nueva mención en un comentario"
    )
  end
end
