class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable
  has_one_attached :avatar
  has_many :project_users, dependent: :destroy
  has_many :projects, through: :project_users
  has_many :task_assignments, dependent: :destroy
  has_many :tasks, through: :task_assignments
  has_many :notifications, dependent: :destroy
  has_many :comment_mentions, dependent: :destroy
  has_many :channel_memberships, dependent: :destroy
  has_many :channels, through: :channel_memberships
  has_many :conversation_participants, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :message_mentions, dependent: :destroy

  after_create_commit :notify_admin_of_registration

  # Validaciones de avatar movidas al controller para evitar errores en producción
  # validates :avatar, content_type: [ "image/png", "image/jpeg" ], size: { less_than: 5.megabytes }

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    parts = [ first_name, last_name ].map { |s| s.to_s.strip }.reject(&:empty?)
    return parts.map { |p| p[0] }.join.upcase[0, 2] if parts.any?

    email.to_s.strip[0, 2].upcase
  end

  def mention_handle
    base = "#{first_name}.#{last_name}".downcase.gsub(/[^a-z0-9.]/, "")
    base = email.to_s.split("@").first.to_s.downcase.gsub(/[^a-z0-9.]/, "") if base.gsub(".", "").empty?
    base
  end

  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first
    return user if user

    user = where(email: auth.info.email).first
    if user
      user.update(provider: auth.provider, uid: auth.uid)
      return user
    end

    create do |u|
      u.provider = auth.provider
      u.uid = auth.uid
      u.email = auth.info.email
      u.password = Devise.friendly_token[0, 20]
      u.first_name = auth.info.first_name
      u.last_name = auth.info.last_name
      # If you are using confirmable and the provider(s) you use validate emails,
      # uncomment the line below to skip the confirmation emails.
      # u.skip_confirmation!
    end
  end

  private

  def notify_admin_of_registration
    AdminMailer.new_user_registered(self).deliver_later
  rescue StandardError => e
    Rails.logger.error("[AdminMailer] No se pudo encolar la notificación de registro para user##{id}: #{e.class} #{e.message}")
  end
end
