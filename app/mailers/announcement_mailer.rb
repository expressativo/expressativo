class AnnouncementMailer < ApplicationMailer
  def new_announcement_notification(announcement, recipient, author)
    @announcement = announcement
    @project = announcement&.project
    @recipient = recipient
    @author = author

    return if @announcement.nil? || @project.nil? || @recipient&.email.blank?

    mail(
      to: @recipient.email,
      subject: "[#{@project.title.to_s.upcase}] - Nuevo anuncio"
    )
  end
end
