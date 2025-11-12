namespace :solid_queue do
  desc "Setup Solid Queue tables in the database"
  task setup: :environment do
    conn = ActiveRecord::Base.connection

    # Check if tables already exist
    if conn.table_exists?("solid_queue_jobs")
      puts "Solid Queue tables already exist. Skipping setup."
      next
    end

    puts "Creating Solid Queue tables..."
    schema_file = File.read(Rails.root.join("db/queue_schema.rb"))

    conn.transaction do
      eval(schema_file)
    end

    puts "Solid Queue tables created successfully!"
  end

  desc "Check if Solid Queue tables exist"
  task check: :environment do
    tables = ActiveRecord::Base.connection.tables.select { |t| t.start_with?("solid_queue") }

    if tables.any?
      puts "Solid Queue tables found:"
      tables.each { |table| puts "  - #{table}" }
    else
      puts "No Solid Queue tables found. Run 'rails solid_queue:setup' to create them."
    end
  end
end
