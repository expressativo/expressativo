class MentionMailer < ApplicationMailer
  def mention_notification(user, comment)
    @user = user
    @comment = comment
    @commentable = comment&.commentable
    @mentioned_by = comment&.user

    if @commentable.is_a?(Task)
      @task = @commentable
      @project = @task.todo.project
    elsif @commentable.is_a?(Document)
      @document = @commentable
      @project = @document.project
    else
      @project = nil
    end

    return if @commentable.nil? || @project.nil? || @mentioned_by.nil? || user&.email.blank?

    subject = case @commentable
              when Task then "[#{@project.title.to_s.upcase}] - Nueva mención en un comentario de tarea"
              when Document then "[#{@project.title.to_s.upcase}] - Nueva mención en un comentario de documento"
              else "[#{@project.title.to_s.upcase}] - Nueva mención en un comentario"
              end

    mail(to: user.email, subject: subject)
  end
end
