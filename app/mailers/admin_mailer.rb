class AdminMailer < ApplicationMailer
  ADMIN_EMAIL = ENV.fetch("ADMIN_NOTIFICATIONS_EMAIL", "j4viermora@gmail.com").freeze

  def new_user_registered(user)
    @user = user
    return if @user&.email.blank?

    mail(
      to: ADMIN_EMAIL,
      subject: "[TIVO] - Nuevo registro en la plataforma"
    )
  end
end
