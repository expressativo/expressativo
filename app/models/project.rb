class Project < ApplicationRecord
  has_many :project_users, dependent: :destroy
  has_many :users, through: :project_users
  has_many :todos, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :documents, dependent: :nullify
  has_many :activities, dependent: :destroy
  validates :title, presence: true

  scope :for_user, ->(user) { joins(:project_users).where(project_users: { user_id: user.id }) }

  def owner
    project_users.find_by(role: "owner")&.user
  end

  def members
    users.where(project_users: { role: "member" })
  end
end
