# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


user = User.find_or_create_by!(email: 'test@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.first_name = 'Test'
  u.last_name = 'User'
end

project = Project.find_or_create_by!(title: 'Sample Project') do |p|
  p.description = 'A sample project for testing'
end

# Create the project-user relationship
ProjectUser.find_or_create_by!(project: project, user: user) do |pu|
  pu.role = 'owner'
end

puts "Created user: #{user.email}"
puts "Created project: #{project.title}"
