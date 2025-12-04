class Comment < ApplicationRecord
  include TrackableActivity

  belongs_to :task
  belongs_to :user
  has_many :comment_mentions, dependent: :destroy
  has_many :mentioned_users, through: :comment_mentions, source: :user
  has_many :notifications, as: :notifiable, dependent: :destroy

  has_rich_text :content
  validates :content, presence: true

  after_create :process_mentions

  private

  def get_project
    task.todo.project
  end

  def process_mentions
    return unless content.present?

    # Extraer menciones del contenido (formato @username o @email)
    plain_content = content.to_plain_text
    mentions = plain_content.scan(/@(\w+(?:\.\w+)*@?\w*\.?\w*)/).flatten.uniq

    project = task.todo.project

    mentions.each do |mention|
      # Buscar usuario por email o nombre
      mentioned_user = project.users.find_by(email: mention) ||
                      project.users.find_by("CONCAT(first_name, ' ', last_name) LIKE ?", "%#{mention}%") ||
                      project.users.find_by("first_name LIKE ? OR last_name LIKE ?", "%#{mention}%", "%#{mention}%")

      if mentioned_user && mentioned_user != user
        comment_mentions.find_or_create_by(user: mentioned_user)
      end
    end
  end
end
