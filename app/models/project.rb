class Project < ApplicationRecord
  belongs_to :user
  validates :title, presence: true
  has_many :todos, dependent: :destroy
end
