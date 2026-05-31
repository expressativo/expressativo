class QuickNote < ApplicationRecord
  COLORS = %w[yellow pink blue green].freeze

  belongs_to :user

  validates :content, presence: true
  validates :color, inclusion: { in: COLORS }

  default_scope { order(position: :asc, created_at: :desc) }
end
