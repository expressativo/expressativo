class AnnouncementComment < ApplicationRecord
  include TrackableActivity

  belongs_to :announcement
  belongs_to :user

  validates :content, presence: true

  private

  def get_project
    announcement.project
  end
end
