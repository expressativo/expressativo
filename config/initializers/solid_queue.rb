# Skip database configuration during asset precompilation
unless defined?(Rake) && Rake.application.top_level_tasks.include?('assets:precompile')
  Rails.application.configure do
    config.solid_queue.connects_to = { database: { writing: :queue, reading: :queue } }
  end
end
