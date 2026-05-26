class MessageReaction < ApplicationRecord
  belongs_to :message
  belongs_to :user

  validates :emoji, presence: true, length: { maximum: 16 }
  validates :user_id, uniqueness: { scope: [ :message_id, :emoji ] }
end
