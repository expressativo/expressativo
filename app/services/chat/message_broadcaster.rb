module Chat
  class MessageBroadcaster
    def self.call(message, action: :create)
      new(message, action).call
    end

    def initialize(message, action)
      @message = message
      @action = action
    end

    def call
      return unless defined?(ChatChannel)

      broadcast_user_notifications if @action == :create

      ChatChannel.broadcast_to(@message.messageable, payload)

      if @message.thread? && @action == :create
        ChatChannel.broadcast_to(@message.messageable, parent_refresh_payload)
      end
    end

    private

    def broadcast_user_notifications
      return unless defined?(NotificationsChannel)

      recipients.each do |user|
        next if user.id == @message.user_id

        if Chat::Presence::Tracker.online?(user)
          NotificationsChannel.broadcast_to(user, user_notification_payload)
        else
          send_email_notification(user)
        end
      end
    end

    def send_email_notification(user)
      ChatMailer.new_message(user, @message).deliver_later
    rescue => e
      Rails.logger.error("[Chat::MessageBroadcaster] Email failed for user #{user.id}: #{e.class}: #{e.message}")
    end

    def recipients
      case @message.messageable
      when Channel then @message.messageable.members.to_a
      when Conversation then @message.messageable.participants.to_a
      else []
      end
    end

    def user_notification_payload
      msgable = @message.messageable
      project = @message.project
      sender = @message.user
      {
        action: "chat_message",
        scope: @message.thread? ? "thread" : "main",
        message_id: @message.id,
        messageable_type: @message.messageable_type,
        messageable_id: @message.messageable_id,
        project_id: project&.id,
        sender_id: sender&.id,
        sender_name: sender&.full_name.presence || sender&.email,
        sender_avatar_url: sender_avatar_url,
        title: notification_title(msgable),
        preview: @message.body.to_s.truncate(140),
        url: notification_url(project, msgable)
      }
    end

    def sender_avatar_url
      sender = @message.user
      return nil unless sender&.avatar&.attached?

      # Intentar URL directa del servicio (S3/R2)
      blob = sender.avatar.blob
      url = blob.url if blob.respond_to?(:url)
      return url if url.present?

      # Fallback a ruta de ActiveStorage (requiere host configurado)
      Rails.application.routes.url_helpers.rails_blob_url(sender.avatar)
    rescue => e
      nil
    end

    def notification_title(msgable)
      case msgable
      when Channel then "##{msgable.name}"
      when Conversation then "Mensaje directo"
      end
    end

    def notification_url(project, msgable)
      return nil unless project && msgable

      url_helpers = Rails.application.routes.url_helpers
      case msgable
      when Channel
        url_helpers.project_channel_path(project, msgable)
      when Conversation
        url_helpers.project_conversation_path(project, msgable)
      end
    end

    def payload
      {
        action: @action.to_s,
        message_id: @message.id,
        user_id: @message.user_id,
        thread_root_id: @message.parent_message_id,
        scope: @message.thread? ? "thread" : "main",
        html: render_message(@message)
      }
    end

    def parent_refresh_payload
      parent = @message.parent_message
      {
        action: "update",
        message_id: parent.id,
        user_id: parent.user_id,
        thread_root_id: nil,
        scope: "main",
        html: render_message(parent)
      }
    end

    def render_message(message)
      ApplicationController.renderer.render(
        partial: "messages/message",
        locals: { message: message, project: message.project, viewer: nil }
      )
    rescue => e
      Rails.logger.error("[Chat::MessageBroadcaster] render failed: #{e.class}: #{e.message}")
      nil
    end
  end
end
