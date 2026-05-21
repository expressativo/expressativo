class ChannelMembership < ApplicationRecord
  NOTIFICATION_SETTINGS = %w[all mentions none].freeze

  belongs_to :channel
  belongs_to :user

  validates :user_id, uniqueness: { scope: :channel_id }
  validates :notifications_setting, inclusion: { in: NOTIFICATION_SETTINGS }

  def muted?
    muted_until.present? && muted_until > Time.current
  end
end
