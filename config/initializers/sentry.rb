# frozen_string_literal: true

# Only initialize Sentry in production environment
if Rails.env.production?
  Sentry.init do |config|
    config.breadcrumbs_logger = [:active_support_logger]
    config.dsn = Rails.application.credentials.dig(:sentry_dsn)
    config.traces_sample_rate = 1.0
  end
end
