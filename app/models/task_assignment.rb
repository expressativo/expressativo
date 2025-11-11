class TaskAssignment < ApplicationRecord
  belongs_to :task
  belongs_to :user
  
  validates :user_id, uniqueness: { scope: :task_id }
end
