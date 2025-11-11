class Document < ApplicationRecord
  include TrackableActivity

  belongs_to :project
  belongs_to :created_by, class_name: "User"
  has_one_attached :file

  enum :status, {
    draft: "draft",
    published: "published",
    archived: "archived"
  }

  validates :title, presence: true
  validates :status, presence: true
end
