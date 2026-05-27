class CommentMention < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  validates :user_id, uniqueness: { scope: :comment_id }

  after_create_commit :dispatch_notification

  private

  def dispatch_notification
    return unless user&.email.present?
    return unless comment&.task&.todo&.project.present?

    NotificationDispatcher.call(
      user: user,
      notifiable: comment,
      notification_type: "mention",
      metadata: {
        comment_id: comment.id,
        task_id: comment.task.id,
        task_title: comment.task.title,
        mentioned_by: comment.user.full_name.presence || comment.user.email,
        comment_preview: comment.content.to_plain_text.truncate(100)
      },
      mailer: MentionMailer,
      mailer_method: :mention_notification,
      mailer_args: [user, comment]
    )
  end
end
