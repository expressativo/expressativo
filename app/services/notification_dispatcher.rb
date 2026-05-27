# Centralizes notification delivery logic:
# - Creates a Notification record
# - If user is online -> broadcasts via ActionCable (NotificationsChannel)
# - If user is offline -> sends email (if mailer is provided)
# - If user has push subscriptions -> sends Web Push
class NotificationDispatcher
  def self.call(user:, notifiable:, notification_type:, metadata:, mailer: nil, mailer_method: nil, mailer_args: [])
    new(user, notifiable, notification_type, metadata, mailer, mailer_method, mailer_args).call
  end

  def initialize(user, notifiable, notification_type, metadata, mailer, mailer_method, mailer_args)
    @user = user
    @notifiable = notifiable
    @notification_type = notification_type
    @metadata = metadata
    @mailer = mailer
    @mailer_method = mailer_method
    @mailer_args = mailer_args
  end

  def call
    notification = create_notification!
    return nil unless notification

    if online?
      broadcast!(notification)
    else
      send_email!
    end

    send_push!(notification)

    notification
  rescue => e
    Rails.logger.error("[NotificationDispatcher] Error dispatching notification to user #{@user&.id}: #{e.class}: #{e.message}")
    nil
  end

  private

  def create_notification!
    Notification.create!(
      user: @user,
      notifiable: @notifiable,
      notification_type: @notification_type,
      metadata: @metadata
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[NotificationDispatcher] Failed to create notification: #{e.message}")
    nil
  end

  def online?
    return false unless @user
    Chat::Presence::Tracker.online?(@user)
  end

  def broadcast!(notification)
    return unless defined?(NotificationsChannel)

    NotificationsChannel.broadcast_to(@user, {
      action: "new",
      notification_id: notification.id,
      unread_count: @user.notifications.unread.count
    })
  end

  def send_email!
    return unless @mailer.present? && @mailer_method.present? && @user&.email.present?

    @mailer.public_send(@mailer_method, *@mailer_args).deliver_later
  rescue => e
    Rails.logger.error("[NotificationDispatcher] Email failed for user #{@user.id}: #{e.class}: #{e.message}")
  end

  def send_push!(notification)
    return unless defined?(PushNotificationService)

    PushNotificationService.call(@user, notification)
  rescue => e
    Rails.logger.error("[NotificationDispatcher] Push failed for user #{@user.id}: #{e.class}: #{e.message}")
  end
end
