class Channels::MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context
  before_action :set_message, only: [ :update, :destroy ]
  before_action :ensure_author, only: [ :update, :destroy ]

  def create
    @message = @channel.messages.build(message_params)
    @message.user = current_user

    if @message.save
      Chat::MentionDispatcher.call(@message)
      Chat::MessageBroadcaster.call(@message)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_channel_path(@project, @channel) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { message: @message, messageable: @channel, project: @project }), status: :unprocessable_entity }
        format.html { redirect_to project_channel_path(@project, @channel), alert: @message.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    if @message.update(body: message_params[:body], edited_at: Time.current)
      Chat::MessageBroadcaster.call(@message, action: :update)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_channel_path(@project, @channel) }
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
      format.html { redirect_to project_channel_path(@project, @channel) }
    end
  end

  private

  def set_context
    @project = Project.for_user(current_user).find(params[:project_id])
    @channel = @project.channels.find(params[:channel_id])
    raise ActiveRecord::RecordNotFound unless @channel.members.exists?(id: current_user.id)
  end

  def set_message
    @message = @channel.messages.kept.find(params[:id])
  end

  def ensure_author
    raise ActiveRecord::RecordNotFound unless @message.user_id == current_user.id
  end

  def message_params
    params.require(:message).permit(:body, :parent_message_id)
  end
end
