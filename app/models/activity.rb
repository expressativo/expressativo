class Activity < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :trackable, polymorphic: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_project, ->(project) { where(project: project) }
  scope :grouped_by_date, -> { group_by { |activity| activity.created_at.to_date } }

  def self.log(project:, user:, trackable:, action:, metadata: {})
    create!(
      project: project,
      user: user,
      trackable: trackable,
      action: action,
      metadata: metadata
    )
  end

  def description
    case action
    when "created"
      "created #{trackable_type_humanized}"
    when "updated"
      "updated #{trackable_type_humanized}"
    when "completed"
      "completed #{trackable_type_humanized}"
    when "deleted"
      "deleted #{trackable_type_humanized}"
    when "commented"
      "commented on #{trackable_type_humanized}"
    when "archived"
      "archived #{trackable_type_humanized}"
    when "published"
      "published #{trackable_type_humanized}"
    else
      action
    end
  end

  def trackable_type_humanized
    case trackable_type
    when "Todo"
      metadata["title"] || "a todo"
    when "Task"
      metadata["title"] || "a task"
    when "Document"
      metadata["title"] || "a document"
    when "Announcement"
      metadata["title"] || "an announcement"
    when "Comment", "AnnouncementComment"
      "a comment"
    else
      trackable_type.downcase
    end
  end
end
