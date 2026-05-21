class MessageReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message

  MAX_EMOJI_LENGTH = 16

  def toggle
    emoji = params[:emoji].to_s.strip
    return head :unprocessable_entity if emoji.empty? || emoji.length > MAX_EMOJI_LENGTH

    existing = @message.reactions.find_by(user_id: current_user.id, emoji: emoji)
    if existing
      existing.destroy
    else
      @message.reactions.create!(user: current_user, emoji: emoji)
    end

    Chat::MessageBroadcaster.call(@message, action: :update)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          view_context.dom_id(@message),
          partial: "messages/message",
          locals: { message: @message, project: @message.project, viewer: current_user }
        )
      end
      format.json { head :ok }
    end
  end

  private

  def set_message
    @message = Message.includes(:messageable).find(params[:message_id])
    authorize_access!
  end

  def authorize_access!
    case @message.messageable
    when Channel
      raise ActiveRecord::RecordNotFound unless @message.messageable.members.exists?(id: current_user.id)
    when Conversation
      raise ActiveRecord::RecordNotFound unless @message.messageable.participants.exists?(id: current_user.id)
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
