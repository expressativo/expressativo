class ProjectUser < ApplicationRecord
  belongs_to :project
  belongs_to :user

  ROLES = %w[owner member viewer].freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :project_id }

  def viewer?
    role == "viewer"
  end
end
