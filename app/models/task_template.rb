class TaskTemplate < ApplicationRecord
  belongs_to :project
  has_rich_text :notes

  validates :name, presence: true
end
