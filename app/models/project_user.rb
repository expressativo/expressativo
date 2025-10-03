class ProjectUser < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :role, presence: true, inclusion: { in: %w[owner member] }
  validates :user_id, uniqueness: { scope: :project_id }
end
