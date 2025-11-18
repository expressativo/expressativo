# frozen_string_literal: true

# Test job to verify Solid Queue is working in production
# Usage: TestJob.perform_later
class TestJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "TestJob executed successfully at #{Time.current}"
  end
end
