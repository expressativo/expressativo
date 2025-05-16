class Task < ApplicationRecord
  belongs_to :todo

  has_rich_text :notes

  validates :title, presence: true
  validates :done, inclusion: { in: [ true, false ] }
end
