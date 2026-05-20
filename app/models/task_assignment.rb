class TaskAssignment < ApplicationRecord
  belongs_to :task
  belongs_to :user
  
  validates :user_id, uniqueness: { scope: :task_id }

  after_create :send_assignment_notification

  private

  def send_assignment_notification
    TaskAssignmentMailer.assignment_notification(self).deliver_later
  end
end
