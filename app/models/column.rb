class Column < ApplicationRecord
  belongs_to :board
  has_many :tasks, -> { order(position: :asc) }, dependent: :nullify
  
  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
end
