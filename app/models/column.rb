class Column < ApplicationRecord
  KINDS = %w[todo in_progress done custom].freeze

  belongs_to :board
  has_many :tasks, -> { order(position: :asc) }, dependent: :nullify

  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  validates :kind, inclusion: { in: KINDS }
  validate :only_one_done_column_per_board

  before_validation :assign_kind_default, on: :create
  before_validation :assign_default_position, on: :create
  before_save :pin_done_to_last_position, if: -> { done? && board.present? }
  after_save :push_done_after_other_columns, unless: :done?
  before_destroy :prevent_done_destruction

  def todo?
    kind == "todo"
  end

  def in_progress?
    kind == "in_progress"
  end

  def done?
    kind == "done"
  end

  def custom?
    kind == "custom"
  end

  private

  def assign_kind_default
    self.kind ||= "custom"
  end

  def assign_default_position
    return if position.present? || board.blank?

    if done?
      self.position = (board.columns.where.not(id: id).maximum(:position) || -1) + 1
    else
      done_column = board.columns.find_by(kind: "done")
      self.position = done_column ? done_column.position : (board.columns.maximum(:position) || -1) + 1
    end
  end

  def pin_done_to_last_position
    max_other = board.columns.where.not(id: id).maximum(:position) || -1
    self.position = max_other + 1 if position.to_i <= max_other
  end

  def push_done_after_other_columns
    return unless board

    done_column = board.columns.where.not(id: id).find_by(kind: "done")
    return if done_column.nil?

    if done_column.position <= position
      done_column.update_column(:position, position + 1)
    end
  end

  def only_one_done_column_per_board
    return unless done? && board

    duplicate = board.columns.where(kind: "done").where.not(id: id).exists?
    errors.add(:kind, "ya existe una columna 'done' en este tablero") if duplicate
  end

  def prevent_done_destruction
    if done?
      errors.add(:base, "No se puede eliminar la columna 'Done' del tablero")
      throw(:abort)
    end
  end
end
