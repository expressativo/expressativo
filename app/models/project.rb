class Project < ApplicationRecord
  has_many :project_users, dependent: :destroy
  has_many :users, through: :project_users
  has_many :todos, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :documents, dependent: :nullify
  has_many :folders, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :boards, dependent: :destroy
  has_many :publications, dependent: :destroy
  has_many :channels, dependent: :destroy
  has_many :conversations, dependent: :destroy
  validates :title, presence: true

  before_create :generate_invitation_token

  scope :for_user, ->(user) { joins(:project_users).where(project_users: { user_id: user.id }) }
  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def owner
    project_users.find_by(role: "owner")&.user
  end

  def members
    users.where(project_users: { role: "member" })
  end

  def viewers
    users.where(project_users: { role: "viewer" })
  end

  def role_for(user)
    project_users.find_by(user_id: user.id)&.role
  end

  def viewer?(user)
    role_for(user) == "viewer"
  end

  def regenerate_invitation_token!
    update(invitation_token: generate_unique_token)
  end

  private

  def generate_invitation_token
    self.invitation_token = generate_unique_token
  end

  def generate_unique_token
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless Project.exists?(invitation_token: token)
    end
  end
end
