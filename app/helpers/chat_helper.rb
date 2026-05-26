module ChatHelper
  def render_chat_message(message, project)
    Chat::MarkdownRenderer.call(message.body, project: project)
  end

  def chat_message_time(time)
    return "" if time.nil?

    if time.to_date == Date.current
      time.strftime("%H:%M")
    elsif time > 6.days.ago
      time.strftime("%a %H:%M")
    else
      time.strftime("%d %b, %H:%M")
    end
  end

  def chat_attachment_size(bytes)
    return "" if bytes.nil? || bytes.zero?

    number_to_human_size(bytes, precision: 2, significant: false)
  end

  def chat_thread_path(message, project)
    case message.messageable
    when Channel
      project_channel_message_replies_path(project, message.messageable, message)
    when Conversation
      project_conversation_message_replies_path(project, message.messageable, message)
    end
  end

  def chat_unread_count_for(membership, channel)
    return 0 if membership.nil?

    scope = channel.messages.kept.top_level
    scope = scope.where("messages.created_at > ?", membership.last_read_at) if membership.last_read_at
    scope.count
  end

  def chat_unread_count_for_conversation(participant, conversation)
    return 0 if participant.nil?

    scope = conversation.messages.kept.top_level
    scope = scope.where("messages.created_at > ?", participant.last_read_at) if participant.last_read_at
    scope.count
  end
end
