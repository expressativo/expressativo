class ChatChannel < ApplicationCable::Channel
  def subscribed
    messageable = find_messageable
    return reject unless messageable
    return reject unless authorized?(messageable)

    stream_for messageable
  end

  def unsubscribed
  end

  private

  def find_messageable
    type = params[:messageable_type].to_s
    id = params[:messageable_id].to_i
    return nil unless %w[Channel Conversation].include?(type)
    return nil if id <= 0

    type.constantize.find_by(id: id)
  end

  def authorized?(messageable)
    project = messageable.project
    return false unless project
    return false unless project.users.exists?(id: current_user.id)

    case messageable
    when Channel
      messageable.channel_memberships.exists?(user_id: current_user.id)
    when Conversation
      messageable.participants.exists?(id: current_user.id)
    else
      false
    end
  end
end
