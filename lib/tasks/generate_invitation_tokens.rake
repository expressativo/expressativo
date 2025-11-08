namespace :projects do
  desc "Generate invitation tokens for existing projects"
  task generate_invitation_tokens: :environment do
    projects_without_token = Project.where(invitation_token: nil)
    
    puts "Generando tokens para #{projects_without_token.count} proyectos..."
    
    projects_without_token.find_each do |project|
      project.send(:generate_invitation_token)
      project.save(validate: false)
      puts "Token generado para proyecto: #{project.title}"
    end
    
    puts "¡Completado! Todos los proyectos ahora tienen tokens de invitación."
  end
end
