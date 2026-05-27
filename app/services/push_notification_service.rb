# Sends Web Push notifications through the user's push subscriptions.
# Requires VAPID keys in Rails credentials (config/credentials/*.yml.enc):
#   web_push:
#     public_key:  "..."
#     private_key: "..."
#     subject:     "mailto:admin@tivo.app"  # optional
class PushNotificationService
  def self.call(user, notification)
    new(user, notification).call
  end

  def initialize(user, notification)
    @user = user
    @notification = notification
  end

  def call
    return if vapid_keys_missing?
    return unless @notification

    subscriptions = @user.push_subscriptions
    return if subscriptions.none?

    payload = build_payload

    subscriptions.each do |sub|
      send_push(sub, payload)
    end
  end

  private

  def vapid_keys_missing?
    vapid_public_key.blank? || vapid_private_key.blank?
  end

  def vapid_public_key
    Rails.application.credentials.dig(:web_push, :public_key) || ENV["VAPID_PUBLIC_KEY"]
  end

  def vapid_private_key
    Rails.application.credentials.dig(:web_push, :private_key) || ENV["VAPID_PRIVATE_KEY"]
  end

  def vapid_subject
    Rails.application.credentials.dig(:web_push, :subject) || ENV["VAPID_SUBJECT"] || "mailto:admin@tivo.app"
  end

  def build_payload
    {
      title: notification_title,
      body: notification_body,
      icon: "/icon-192x192.png",
      badge: "/badge-72x72.png",
      url: notification_url,
      tag: "tivo-notification-#{@notification.id}",
      requireInteraction: false
    }.to_json
  end

  def notification_title
    case @notification.notification_type
    when "mention" then "Nueva mención en comentario"
    when "chat_mention" then "Nueva mención en chat"
    when "task_assignment" then "Nueva tarea asignada"
    when "direct_message" then "Nuevo mensaje directo"
    else "Nueva notificación"
    end
  end

  def notification_body
    @notification.metadata["preview"] ||
      @notification.metadata["comment_preview"] ||
      @notification.metadata["task_title"] ||
      "Tienes una nueva notificación en Tivo"
  end

  def notification_url
    notifiable = @notification.notifiable
    return "/notifications" unless notifiable

    case @notification.notification_type
    when "mention"
      task = notifiable.task
      Rails.application.routes.url_helpers.project_todo_task_path(task.todo.project, task.todo, task)
    when "chat_mention"
      msgable = notifiable.messageable
      project = notifiable.project
      if msgable.is_a?(Channel)
        Rails.application.routes.url_helpers.project_channel_path(project, msgable)
      elsif msgable.is_a?(Conversation)
        Rails.application.routes.url_helpers.project_conversation_path(project, msgable)
      else
        "/notifications"
      end
    when "task_assignment"
      task = notifiable
      Rails.application.routes.url_helpers.project_todo_task_path(task.todo.project, task.todo, task)
    when "direct_message"
      conversation = notifiable.messageable
      Rails.application.routes.url_helpers.project_conversation_path(conversation.project, conversation)
    else
      "/notifications"
    end
  rescue StandardError
    "/notifications"
  end

  def send_push(subscription, payload)
    WebPush.payload_send(
      message: payload,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh,
      auth: subscription.auth,
      vapid: {
        subject: vapid_subject,
        public_key: vapid_public_key,
        private_key: vapid_private_key
      }
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
  rescue WebPush::ResponseError => e
    subscription.destroy if e.response&.code == 410
  rescue StandardError => e
    Rails.logger.error("[PushNotificationService] Push failed for subscription #{subscription.id}: #{e.class}: #{e.message}")
  end
end
