class Task < ApplicationRecord
  include TrackableActivity

  belongs_to :todo
  belongs_to :created_by, class_name: "User"
  belongs_to :column, optional: true
  has_rich_text :notes
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :done, inclusion: { in: [ true, false ] }

  def completed?
    done
  end

  def saved_change_to_completed?
    saved_change_to_done?
  end
end
