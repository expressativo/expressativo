class Announcement < ApplicationRecord
  include TrackableActivity

  belongs_to :project
  has_many :announcement_comments, dependent: :destroy
  has_rich_text :content
  validates :content, presence: true
end
