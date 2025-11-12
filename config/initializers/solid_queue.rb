Rails.application.configure do
  config.solid_queue.connects_to = { database: { writing: :queue, reading: :queue } }
end
