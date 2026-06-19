class ProjectCustomField < ApplicationRecord
  FIELD_TYPES = %w[text number date select].freeze

  belongs_to :project
  has_many :task_custom_field_values, dependent: :destroy

  serialize :options, coder: JSON

  validates :name, presence: true
  validates :field_type, inclusion: { in: FIELD_TYPES }
  validates :options, presence: true, if: -> { field_type == "select" }

  default_scope { order(:position, :id) }

  before_create :set_position

  def options_list
    return [] unless options.is_a?(Array)

    options
  end

  private

  def set_position
    self.position = (project.custom_fields.maximum(:position) || -1) + 1
  end
end
