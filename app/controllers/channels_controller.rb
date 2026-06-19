class ChannelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action -> { require_non_viewer!(@project) }
  before_action :set_channel, only: [ :show, :edit, :update, :destroy, :mark_read ]
  before_action :ensure_member, only: [ :show, :mark_read ]

  def index
    @channels = @project.channels.active.order(:name)
    redirect_to project_channel_path(@project, @channels.first) and return if @channels.any?
  end

  def show
    @messages = @channel.messages.kept.top_level.with_attached_files.includes(:user, :mentioned_users, replies: :user).chronological.last(100)
    @message = @channel.messages.build
    @previous_last_read_at = membership&.last_read_at
    membership.update(last_read_at: Time.current) if membership
  end

  def new
    @channel = @project.channels.build
  end

  def create
    @channel = @project.channels.build(channel_params)
    @channel.creator = current_user

    if @channel.save
      @channel.channel_memberships.create!(user: current_user)
      redirect_to project_channel_path(@project, @channel), notice: "Canal creado"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @channel.update(channel_params)
      redirect_to project_channel_path(@project, @channel), notice: "Canal actualizado"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @channel.archive!
    redirect_to project_channels_path(@project), notice: "Canal archivado"
  end

  def mark_read
    membership&.update(last_read_at: Time.current)
    head :no_content
  end

  private

  def set_project
    @project = Project.for_user(current_user).find(params[:project_id])
  end

  def set_channel
    @channel = @project.channels.find(params[:id])
  end

  def ensure_member
    return if membership

    @channel.channel_memberships.create!(user: current_user)
    @membership = nil
  end

  def membership
    @membership ||= @channel.channel_memberships.find_by(user_id: current_user.id)
  end

  def channel_params
    params.require(:channel).permit(:name, :description, :kind)
  end
end
