class Conversation < ApplicationRecord
  belongs_to :project
  belongs_to :user_one, class_name: "User"
  belongs_to :user_two, class_name: "User"
  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, as: :messageable, dependent: :destroy

  validates :user_one_id, uniqueness: { scope: [ :project_id, :user_two_id ] }
  validate :distinct_users
  validate :canonical_user_order

  after_create :create_participants

  scope :for_user, ->(user) { where("user_one_id = :id OR user_two_id = :id", id: user.id) }

  def self.between(project, user_a, user_b)
    one, two = [ user_a.id, user_b.id ].sort
    find_or_create_by(project: project, user_one_id: one, user_two_id: two)
  end

  def other_user_for(user)
    user_one_id == user.id ? user_two : user_one
  end

  private

  def distinct_users
    return if user_one_id.nil? || user_two_id.nil?

    errors.add(:user_two_id, "no puede ser igual al primer usuario") if user_one_id == user_two_id
  end

  def canonical_user_order
    return if user_one_id.nil? || user_two_id.nil?

    errors.add(:base, "los ids de usuarios deben estar ordenados") if user_one_id > user_two_id
  end

  def create_participants
    ConversationParticipant.create!(conversation: self, user_id: user_one_id)
    ConversationParticipant.create!(conversation: self, user_id: user_two_id)
  end
end
