class ChatMailer < ApplicationMailer
  def new_message(user, message)
    @user = user
    @message = message
    @sender = message.user
    @msgable = message.messageable
    @project = message.project

    return if @project.nil? || @sender.nil? || user&.email.blank?

    @chat_name = chat_name
    @url = chat_url

    mail(
      to: user.email,
      subject: "[#{@project.title.to_s.upcase}] - Nuevo mensaje en #{@chat_name}"
    )
  end

  private

  def chat_name
    case @msgable
    when Channel then "##{@msgable.name}"
    when Conversation then "Mensaje directo"
    else "Chat"
    end
  end

  def chat_url
    url_helpers = Rails.application.routes.url_helpers
    case @msgable
    when Channel
      url_helpers.project_channel_url(@project, @msgable)
    when Conversation
      url_helpers.project_conversation_url(@project, @msgable)
    end
  end
end
