class CommentMention < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  validates :user_id, uniqueness: { scope: :comment_id }

  after_create :create_notification
  after_create :send_mention_email

  private

  def create_notification
    Notification.create(
      user: user,
      notifiable: comment,
      notification_type: "mention",
      metadata: {
        comment_id: comment.id,
        task_id: comment.task.id,
        task_title: comment.task.title,
        mentioned_by: comment.user.full_name || comment.user.email,
        comment_preview: comment.content.to_plain_text.truncate(100)
      }
    )
  end

  def send_mention_email
    MentionMailer.mention_notification(user, comment).deliver_later
  end
end
