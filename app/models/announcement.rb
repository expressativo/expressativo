class Announcement < ApplicationRecord
  include TrackableActivity

  belongs_to :project
  has_many :announcement_comments, dependent: :destroy
  validates :content, presence: true
end
