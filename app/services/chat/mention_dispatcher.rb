module Chat
  class MentionDispatcher
    def self.call(message)
      new(message).call
    end

    def initialize(message)
      @message = message
    end

    def call
      return if project.nil?

      mentioned = Chat::MentionParser.call(@message.body, project: project)
      mentioned = mentioned.reject { |u| u.id == @message.user_id }
      return if mentioned.empty?

      mentioned.each do |user|
        MessageMention.find_or_create_by!(message: @message, user: user)
        dispatch_to(user)
      end
    end

    private

    def project
      @project ||= @message.project
    end

    def dispatch_to(user)
      NotificationDispatcher.call(
        user: user,
        notifiable: @message,
        notification_type: "chat_mention",
        metadata: notification_metadata,
        mailer: ChatMailer,
        mailer_method: :new_message,
        mailer_args: [user, @message]
      )
    end

    def notification_metadata
      {
        message_id: @message.id,
        messageable_type: @message.messageable_type,
        messageable_id: @message.messageable_id,
        project_id: project.id,
        mentioned_by: @message.user.full_name.presence || @message.user.email,
        preview: @message.body.to_s.strip.truncate(120).presence || "[Archivo adjunto]"
      }
    end
  end
end
