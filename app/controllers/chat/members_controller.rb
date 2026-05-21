class Chat::MembersController < ApplicationController
  before_action :authenticate_user!

  def index
    @project = Project.for_user(current_user).find(params[:project_id])
    query = params[:q].to_s.downcase.strip

    members = @project.users
    if query.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      members = members.where(
        "LOWER(users.first_name) LIKE :q OR LOWER(users.last_name) LIKE :q OR LOWER(users.email) LIKE :q",
        q: like
      )
    end

    payload = members.limit(10).map do |user|
      {
        id: user.id,
        handle: user.mention_handle,
        label: user.full_name.to_s.strip.presence || user.email,
        email: user.email
      }
    end

    render json: payload
  end
end
