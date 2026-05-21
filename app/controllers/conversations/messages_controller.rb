class Conversations::MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context
  before_action :set_message, only: [ :update, :destroy ]
  before_action :ensure_author, only: [ :update, :destroy ]

  def create
    @message = @conversation.messages.build(message_params)
    @message.user = current_user

    if @message.save
      Chat::MentionDispatcher.call(@message)
      Chat::MessageBroadcaster.call(@message)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_conversation_path(@project, @conversation) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { message: @message, messageable: @conversation, project: @project }), status: :unprocessable_entity }
        format.html { redirect_to project_conversation_path(@project, @conversation), alert: @message.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    if @message.update(body: message_params[:body], edited_at: Time.current)
      Chat::MessageBroadcaster.call(@message, action: :update)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_conversation_path(@project, @conversation) }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @message.soft_delete!
    Chat::MessageBroadcaster.call(@message, action: :update)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to project_conversation_path(@project, @conversation) }
    end
  end

  private

  def set_context
    @project = Project.for_user(current_user).find(params[:project_id])
    @conversation = @project.conversations.find(params[:conversation_id])
    raise ActiveRecord::RecordNotFound unless @conversation.participants.exists?(id: current_user.id)
  end

  def set_message
    @message = @conversation.messages.kept.find(params[:id])
  end

  def ensure_author
    raise ActiveRecord::RecordNotFound unless @message.user_id == current_user.id
  end

  def message_params
    params.require(:message).permit(:body, :parent_message_id)
  end
end
