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

  scope :pending, -> { where(done: false) }

  before_save :sync_done_with_column
  after_update :sync_publication

  def completed?
    done
  end

  def saved_change_to_completed?
    saved_change_to_done?
  end

  private

  def sync_done_with_column
    # Solo sincronizar si cambió la columna y no se está cambiando done manualmente
    if column_id_changed? && column.present? && !done_changed?
      board = column.board
      last_column = board.columns.reorder(position: :desc).first
      self.done = (column.id == last_column.id)
    end
  end

  def sync_publication
    publication&.update(title: title, publication_date: due_date, description: notes)
  end
end
