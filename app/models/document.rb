class Document < ApplicationRecord
  belongs_to :project
  has_one_attached :file

  enum :status, {
    draft: "draft",
    published: "published",
    archived: "archived"
  }

  validates :title, presence: true
  validates :status, presence: true
end
