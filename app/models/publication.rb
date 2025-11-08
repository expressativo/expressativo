class Publication < ApplicationRecord
  belongs_to :project
  belongs_to :task, optional: true

  validates :title, presence: true
  validates :publication_date, presence: true

  scope :for_month, ->(year, month) {
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(publication_date: start_date..end_date)
  }
end
