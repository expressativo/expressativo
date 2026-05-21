class Message < ApplicationRecord
  belongs_to :messageable, polymorphic: true
  belongs_to :user
  belongs_to :parent_message, class_name: "Message", optional: true
  has_many :replies, class_name: "Message", foreign_key: "parent_message_id", dependent: :destroy
  has_many :message_mentions, dependent: :destroy
  has_many :mentioned_users, through: :message_mentions, source: :user

  validates :body, presence: true, length: { maximum: 10_000 }
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

  def project
    case messageable
    when Channel then messageable.project
    when Conversation then messageable.project
    end
  end

  private

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
