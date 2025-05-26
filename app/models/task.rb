class Task < ApplicationRecord
  belongs_to :todo
  belongs_to :created_by, class_name: "User"
  has_rich_text :notes
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :done, inclusion: { in: [ true, false ] }
end
