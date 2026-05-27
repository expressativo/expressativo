class TaskAssignment < ApplicationRecord
  belongs_to :task
  belongs_to :user
  
  validates :user_id, uniqueness: { scope: :task_id }

  after_create :dispatch_notification

  private

  def dispatch_notification
    return unless user&.email.present?
    return unless task&.todo&.project.present?

    NotificationDispatcher.call(
      user: user,
      notifiable: task,
      notification_type: "task_assignment",
      metadata: {
        task_id: task.id,
        task_title: task.title,
        assigned_by: task.created_by&.full_name.presence || task.created_by&.email,
        project_id: task.todo.project.id,
        project_title: task.todo.project.title
      },
      mailer: TaskAssignmentMailer,
      mailer_method: :assignment_notification,
      mailer_args: [self]
    )
  end
end
