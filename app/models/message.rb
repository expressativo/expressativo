class Message < ApplicationRecord
  belongs_to :messageable, polymorphic: true
  belongs_to :user
  belongs_to :parent_message, class_name: "Message", optional: true
  has_many :replies, class_name: "Message", foreign_key: "parent_message_id", dependent: :destroy
  has_many :message_mentions, dependent: :destroy
  has_many :mentioned_users, through: :message_mentions, source: :user
  has_many :reactions, class_name: "MessageReaction", dependent: :destroy
  has_many_attached :files

  validates :body, length: { maximum: 10_000 }
  validates :files,
            size: { less_than: 25.megabytes, message: "no puede superar 25 MB" }
  validate :body_or_files_present
  validate :parent_belongs_to_same_messageable

  scope :kept, -> { where(deleted_at: nil) }
  scope :top_level, -> { where(parent_message_id: nil) }
  scope :chronological, -> { order(created_at: :asc) }

  after_create_commit :touch_messageable

  def deleted?
    deleted_at.present?
  end

  def edited?
    edited_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current, body: "")
  end

  def thread?
    parent_message_id.present?
  end

  def reactions_summary(viewer = nil)
    reactions.includes(:user).group_by(&:emoji).map do |emoji, list|
      {
        emoji: emoji,
        count: list.size,
        users: list.map(&:user),
        reacted_by_viewer: viewer.present? && list.any? { |r| r.user_id == viewer.id }
      }
    end.sort_by { |r| -r[:count] }
  end

  def project
    case messageable
    when Channel then messageable.project
    when Conversation then messageable.project
    end
  end

  private

  def body_or_files_present
    return if body.to_s.strip.present?
    return if files.attached?

    errors.add(:body, "no puede estar vacío")
  end

  def parent_belongs_to_same_messageable
    return if parent_message.nil?

    if parent_message.messageable_type != messageable_type || parent_message.messageable_id != messageable_id
      errors.add(:parent_message_id, "debe pertenecer al mismo canal o conversación")
    end
  end

  def touch_messageable
    return unless messageable.respond_to?(:last_message_at)

    messageable.update_column(:last_message_at, created_at) if messageable.has_attribute?(:last_message_at)
  end
end
