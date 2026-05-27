# Notifies participants of a conversation (DM) about a new message.
# Unlike channels, direct messages always generate a notification.
# Uses NotificationDispatcher so push/email/ActionCable are all handled.
module Chat
  class ConversationNotifier
    def self.call(message)
      new(message).call
    end

    def initialize(message)
      @message = message
    end

    def call
      return unless @message.messageable.is_a?(Conversation)

      conversation = @message.messageable
      recipient = conversation.other_user_for(@message.user)
      return if recipient.nil?
      # Skip if the recipient was already notified via MentionDispatcher (chat_mention)
      return if @message.message_mentions.exists?(user: recipient)

      NotificationDispatcher.call(
        user: recipient,
        notifiable: @message,
        notification_type: "direct_message",
        metadata: notification_metadata
      )
    end

    private

    def notification_metadata
      {
        message_id: @message.id,
        conversation_id: @message.messageable_id,
        project_id: @message.project.id,
        sender_name: @message.user.full_name.presence || @message.user.email,
        preview: @message.body.to_s.strip.truncate(120).presence || "[Archivo adjunto]"
      }
    end
  end
end
