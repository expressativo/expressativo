class ProjectInvitationMailer < ApplicationMailer
  def invite(project:, email:, inviter:)
    @project = project
    @email   = email&.to_s&.strip
    @inviter = inviter
    @invitation_url = project_invitation_url(token: project.invitation_token)

    return if @project.nil? || @email.blank?

    mail(
      to: @email,
      subject: "[#{@project.title.to_s.upcase}] - Te han invitado al proyecto"
    )
  end
end
