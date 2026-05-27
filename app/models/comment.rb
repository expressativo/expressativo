class Comment < ApplicationRecord
  include TrackableActivity

  belongs_to :task
  belongs_to :user
  has_many :comment_mentions, dependent: :destroy
  has_many :mentioned_users, through: :comment_mentions, source: :user
  has_many :notifications, as: :notifiable, dependent: :destroy

  has_rich_text :content
  validates :content, presence: true

  after_create_commit :process_mentions

  private

  def get_project
    task.todo.project
  end

  def process_mentions
    return unless content.present?

    project = task.todo.project
    plain_content = content.to_plain_text

    mentioned_users = Chat::MentionParser.call(plain_content, project: project)
    mentioned_users.reject { |u| u.id == user_id }.each do |mentioned_user|
      comment_mentions.find_or_create_by(user: mentioned_user)
    end
  end
end
