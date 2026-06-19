class ProjectCustomField < ApplicationRecord
  FIELD_TYPES = %w[text number date select link map].freeze

  belongs_to :project
  has_many :task_custom_field_values, dependent: :destroy

  serialize :options, coder: JSON

  validates :name, presence: true
  validates :field_type, inclusion: { in: FIELD_TYPES }
  validates :options, presence: true, if: -> { field_type == "select" }

  default_scope { order(:position, :id) }

  before_create :set_position

  def self.maps_embed_url(value)
    return nil if value.blank?

    # Extrae el src si pegaron el iframe completo
    url = if value.include?("<iframe")
      value.match(/src="([^"]+)"/)&.captures&.first || value
    else
      value
    end

    return nil if url.match?(%r{goo\.gl|maps\.app\.goo\.gl})
    return url if url.include?("maps/embed")

    if url.match?(%r{google\.com/maps})
      url.sub("maps?", "maps/embed?").then do |u|
        u.include?("output=embed") ? u : "#{u}&output=embed"
      end
    else
      "https://maps.google.com/maps?q=#{CGI.escape(url)}&output=embed"
    end
  end

  def options_list
    return [] unless options.is_a?(Array)

    options
  end

  private

  def set_position
    self.position = (project.custom_fields.maximum(:position) || -1) + 1
  end
end
