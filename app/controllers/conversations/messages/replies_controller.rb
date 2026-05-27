class Conversations::Messages::RepliesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context

  def index
    @replies = @parent.replies.kept.with_attached_files.includes(:user, :mentioned_users).chronological
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @reply = @conversation.messages.build(reply_params.merge(parent_message: @parent))
    @reply.user = current_user

    if @reply.save
      Chat::MentionDispatcher.call(@reply)
      Chat::ConversationNotifier.call(@reply)
      Chat::MessageBroadcaster.call(@reply)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_conversation_path(@project, @conversation) }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def set_context
    @project = Project.for_user(current_user).find(params[:project_id])
    @conversation = @project.conversations.find(params[:conversation_id])
    raise ActiveRecord::RecordNotFound unless @conversation.participants.exists?(id: current_user.id)

    @parent = @conversation.messages.kept.find(params[:message_id])
  end

  def reply_params
    params.require(:message).permit(:body, files: [])
  end
end
