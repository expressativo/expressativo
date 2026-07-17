class CommentMention < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  validates :user_id, uniqueness: { scope: :comment_id }

  after_create_commit :dispatch_notification

  private

  def dispatch_notification
    return unless user&.email.present?
    return unless comment&.commentable.present?

    commentable = comment.commentable
    project = commentable.respond_to?(:project) ? commentable.project : commentable.todo.project

    NotificationDispatcher.call(
      user: user,
      notifiable: comment,
      notification_type: "mention",
      metadata: {
        comment_id: comment.id,
        commentable_type: commentable.class.name,
        commentable_id: commentable.id,
        commentable_title: commentable_title(commentable),
        mentioned_by: comment.user.full_name.presence || comment.user.email,
        comment_preview: comment.content.to_plain_text.truncate(100)
      },
      mailer: MentionMailer,
      mailer_method: :mention_notification,
      mailer_args: [user, comment]
    )
  end

  def commentable_title(commentable)
    commentable.respond_to?(:title) ? commentable.title : commentable.name
  end
end
