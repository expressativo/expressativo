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

      ChatChannel.broadcast_to(@message.messageable, payload)
    end

    private

    def payload
      {
        action: @action.to_s,
        message_id: @message.id,
        user_id: @message.user_id,
        thread_root_id: @message.parent_message_id,
        scope: @message.thread? ? "thread" : "main",
        html: render_html
      }
    end

    def render_html
      ApplicationController.renderer.render(
        partial: "messages/message",
        locals: { message: @message, project: @message.project, viewer: nil }
      )
    rescue ActionView::Template::Error => e
      Rails.logger.error("[Chat::MessageBroadcaster] render failed: #{e.message}")
      nil
    end
  end
end
