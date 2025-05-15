class Task < ApplicationRecord
  belongs_to :todo

  validates :title, presence: true
  validates :done, inclusion: { in: [ true, false ] }
end
