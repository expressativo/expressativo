class Board < ApplicationRecord
  belongs_to :project
  has_many :columns, -> { order(position: :asc) }, dependent: :destroy

  validates :title, presence: true

  after_create :create_default_columns
  validate :must_have_done_column, on: :update
  validate :must_have_todo_column, on: :update

  def done_column
    columns.find_by(kind: "done")
  end

  def todo_column
    columns.where(kind: "todo").order(:position).first
  end

  private

  def create_default_columns
    columns.create!([
      { title: "Por hacer",   position: 0, kind: "todo" },
      { title: "En progreso", position: 1, kind: "in_progress" },
      { title: "Completado",  position: 2, kind: "done" }
    ])
  end

  def must_have_done_column
    return if columns.any? { |c| c.kind == "done" && !c.marked_for_destruction? }
    errors.add(:base, "El tablero debe tener una columna 'Done'")
  end

  def must_have_todo_column
    return if columns.any? { |c| c.kind == "todo" && !c.marked_for_destruction? }
    errors.add(:base, "El tablero debe tener una columna 'Todo'")
  end
end
