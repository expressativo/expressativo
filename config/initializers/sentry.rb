# frozen_string_literal: true

# Skip Sentry initialization during asset precompilation
unless defined?(Rake) && Rake.application.top_level_tasks.include?('assets:precompile')
  Sentry.init do |config|
    config.breadcrumbs_logger = [:active_support_logger]
    config.dsn = Rails.application.credentials.dig(:sentry_dsn)
    config.traces_sample_rate = 1.0
  end
end
