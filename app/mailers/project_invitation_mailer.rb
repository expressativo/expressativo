class ProjectInvitationMailer < ApplicationMailer
  def invite(project:, email:, inviter:, role: "member")
    @project = project
    @email   = email&.to_s&.strip
    @inviter = inviter
    @invitation_url = project_invitation_url(token: project.invitation_token, role: role)

    return if @project.nil? || @email.blank?

    mail(
      to: @email,
      subject: "[#{@project.title.to_s.upcase}] - Te han invitado al proyecto"
    )
  end
end
