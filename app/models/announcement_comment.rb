class AnnouncementComment < ApplicationRecord
  include TrackableActivity

  belongs_to :announcement
  belongs_to :user

  has_rich_text :content

  private

  def get_project
    announcement.project
  end
end
