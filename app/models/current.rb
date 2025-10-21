class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user

  delegate :user, to: :session, allow_nil: true, prefix: :session
end
