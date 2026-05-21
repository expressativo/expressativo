class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_conversation, only: [ :show, :destroy, :mark_read ]
  before_action :ensure_participant, only: [ :show, :mark_read ]

  def index
    @conversations = @project.conversations
                              .for_user(current_user)
                              .includes(:user_one, :user_two)
                              .order(last_message_at: :desc, created_at: :desc)
    @other_members = @project.users.where.not(id: current_user.id).order(:first_name, :email)
  end

  def show
    @messages = @conversation.messages.kept.top_level.includes(:user, :mentioned_users, replies: :user).chronological.last(50)
    @message = @conversation.messages.build
    participant&.update(last_read_at: Time.current)
  end

  def create
    other_id = params[:user_id].to_i
    raise ActiveRecord::RecordNotFound if other_id <= 0 || other_id == current_user.id

    unless @project.users.exists?(id: other_id)
      redirect_to project_conversations_path(@project), alert: "Usuario no es miembro del proyecto" and return
    end

    other = User.find(other_id)
    @conversation = Conversation.between(@project, current_user, other)
    redirect_to project_conversation_path(@project, @conversation)
  end

  def destroy
    @conversation.destroy
    redirect_to project_conversations_path(@project), notice: "Conversación eliminada"
  end

  def mark_read
    participant&.update(last_read_at: Time.current)
    head :no_content
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end

  def set_conversation
    @conversation = @project.conversations.find(params[:id])
  end

  def ensure_participant
    raise ActiveRecord::RecordNotFound unless @conversation.participants.exists?(id: current_user.id)
  end

  def participant
    @participant ||= @conversation.conversation_participants.find_by(user_id: current_user.id)
  end
end
