class Task < ApplicationRecord
  include TrackableActivity

  belongs_to :todo
  belongs_to :created_by, class_name: "User"
  belongs_to :column, optional: true
  has_rich_text :notes
  has_many :comments, dependent: :destroy
  has_one :publication, dependent: :destroy
  has_many :task_assignments, dependent: :destroy
  has_many :assigned_users, through: :task_assignments, source: :user

  validates :title, presence: true
  validates :done, inclusion: { in: [ true, false ] }

  after_update :sync_publication_title, if: :saved_change_to_title?

  def completed?
    done
  end

  def saved_change_to_completed?
    saved_change_to_done?
  end

  private

  def sync_publication_title
    publication&.update_column(:title, title)
  end
end
