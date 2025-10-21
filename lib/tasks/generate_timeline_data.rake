namespace :timeline do
  desc "Generate sample timeline data for testing"
  task generate_sample_data: :environment do
    puts "Generating sample timeline data..."

    # Get first user and project
    user = User.first
    unless user
      puts "No users found. Please create a user first."
      exit
    end

    project = Project.for_user(user).first
    unless project
      puts "No projects found for user. Creating a sample project..."
      project = Project.create!(title: 'Timeline Test Project', description: 'Project for testing timeline')
      ProjectUser.create!(project: project, user: user, role: 'owner')
      puts "Created project: #{project.title}"
    end

    puts "Using user: #{user.email}"
    puts "Using project: #{project.title}"

    # Set current user for activity tracking
    Current.user = user

    # Create activities from different days
    dates = [
      3.days.ago,
      2.days.ago,
      1.day.ago,
      Time.current
    ]

    dates.each_with_index do |date, day_index|
      # Create a todo
      todo = project.todos.create!(
        name: "Todo from #{date.strftime('%A')}"
      )
      Activity.where(trackable: todo).update_all(created_at: date + 9.hours)
      puts "Created todo: #{todo.name}"

      # Create some tasks for the todo
      2.times do |i|
        task = todo.tasks.create!(
          title: "Task #{i + 1} for #{todo.name}",
          done: false,
          created_by: user
        )
        Activity.where(trackable: task).update_all(created_at: date + (10 + i).hours)
        puts "Created task: #{task.title}"
      end

      # Create an announcement
      announcement = project.announcements.create!(
        content: "Announcement from #{date.strftime('%A')}: This is a sample announcement for testing the timeline feature."
      )
      Activity.where(trackable: announcement).update_all(created_at: date + 14.hours)
      puts "Created announcement"

      # Add a comment to the announcement
      comment = announcement.announcement_comments.create!(
        content: "Great update! This comment is from #{date.strftime('%A')}",
        user: user
      )
      Activity.where(trackable: comment).update_all(created_at: date + 15.hours)
      puts "Created announcement comment"

      # Create a document
      document = project.documents.create!(
        title: "Document from #{date.strftime('%A')}",
        status: :draft
      )
      Activity.where(trackable: document).last.update(created_at: date + 16.hours)
      puts "Created document: #{document.title}"

      # Later publish it
      document.update!(status: :published)
      Activity.where(trackable: document).last.update(created_at: date + 17.hours)
      puts "Published document: #{document.title}"
    end

    puts "\nSample timeline data generated successfully!"
    puts "View the timeline at: /projects/#{project.id}/timeline"
  end
end
