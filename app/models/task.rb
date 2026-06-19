class Task < ApplicationRecord
  include TrackableActivity

  STATUSES = %w[pending in_progress done].freeze

  belongs_to :todo
  belongs_to :created_by, class_name: "User"
  belongs_to :column, optional: true
  has_rich_text :notes
  has_many :comments, dependent: :destroy
  has_one :publication, dependent: :destroy
  has_many :task_assignments, dependent: :destroy
  has_many :assigned_users, through: :task_assignments, source: :user
  has_many :custom_field_values, class_name: "TaskCustomFieldValue", dependent: :destroy
  has_many :custom_fields, through: :custom_field_values, source: :project_custom_field

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending,      -> { where(status: "pending") }
  scope :in_progress,  -> { where(status: "in_progress") }
  scope :done,         -> { where(status: "done") }
  scope :completed,    -> { where(status: "done") }
  scope :not_done,     -> { where.not(status: "done") }
  scope :ordered,      -> { order(:position, :id) }
  scope :list_ordered, -> { order(:list_position, :id) }

  before_create :set_default_position
  before_create :set_default_list_position
  before_save :sync_status_with_column
  before_save :sync_column_with_status
  after_update :sync_publication

  def due_date_has_time?
    return false unless due_date.present?

    due_date.hour != 0 || due_date.min != 0
  end

  def to_ics(task_url:, host:)
    return nil unless due_date.present?

    notes_plain = ActionView::Base.full_sanitizer.sanitize(notes.to_s).strip

    cfv_by_key = custom_field_values.includes(:project_custom_field)
                                    .index_by { |v| v.project_custom_field.key }
                                    .reject { |k, _| k.blank? }

    location_value = cfv_by_key["location"]&.value.presence
    duration_hours = cfv_by_key["duration"]&.value.to_f.positive? ? cfv_by_key["duration"].value.to_f : nil

    if due_date_has_time?
      dtstart_line = "DTSTART:#{due_date.utc.strftime('%Y%m%dT%H%M%SZ')}"
      dtend_time   = duration_hours ? due_date.utc + duration_hours.hours : due_date.utc + 1.hour
      dtend_line   = "DTEND:#{dtend_time.strftime('%Y%m%dT%H%M%SZ')}"
    else
      due = due_date.to_date
      dtstart_line = "DTSTART;VALUE=DATE:#{due.strftime('%Y%m%d')}"
      dtend_line   = "DTEND;VALUE=DATE:#{(due + 1).strftime('%Y%m%d')}"
    end

    [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Tivo//Tivo Tasks//EN",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "BEGIN:VEVENT",
      "UID:tivo-task-#{id}@#{host}",
      "DTSTAMP:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}",
      dtstart_line,
      dtend_line,
      "SUMMARY:#{title}",
      "DESCRIPTION:#{notes_plain.presence || 'Sin descripción'}\\n#{task_url}",
      "URL:#{task_url}",
      (location_value ? "LOCATION:#{location_value}" : nil),
      "BEGIN:VALARM",
      "TRIGGER:-P1D",
      "ACTION:DISPLAY",
      "DESCRIPTION:Recordatorio",
      "END:VALARM",
      "BEGIN:VALARM",
      "TRIGGER:-PT2H",
      "ACTION:DISPLAY",
      "DESCRIPTION:Recordatorio",
      "END:VALARM",
      "END:VEVENT",
      "END:VCALENDAR"
    ].compact.join("\n") + "\n"
  end

  def public?
    public_token.present?
  end

  def publish_publicly!
    return if public?

    update!(
      public_token: SecureRandom.urlsafe_base64(6),
      published_publicly_at: Time.current
    )
  end

  def unpublish_publicly!
    return unless public?

    update!(public_token: nil, published_publicly_at: nil)
  end

  def completed?
    status == "done"
  end

  def completed
    completed?
  end

  def completed=(value)
    bool = ActiveModel::Type::Boolean.new.cast(value)
    if bool
      self.status = "done"
    elsif completed?
      self.status = column_id.present? ? "in_progress" : "pending"
    end
  end

  def saved_change_to_completed?
    saved_change_to_status? && [ saved_change_to_status[0], saved_change_to_status[1] ].include?("done")
  end

  private

  def set_default_position
    return if position.present? && position.positive?

    self.position = (todo.tasks.maximum(:position) || -1) + 1
  end

  def set_default_list_position
    return if list_position.present? && list_position.positive?

    self.list_position = (todo.tasks.maximum(:list_position) || -1) + 1
  end

  # Cuando el usuario cambia la columna de la tarea, ajustar status para que
  # refleje si llegó a la columna "done" o salió de ella.
  def sync_status_with_column
    return unless column_id_changed?
    return if status_changed? # priorizar el cambio manual de status

    if column.present? && column.kind == "done"
      self.status = "done"
    elsif completed?
      self.status = "in_progress"
    end
  end

  # Cuando el usuario marca/desmarca el check (cambia status), reflejar el
  # movimiento en el tablero: ir a la columna "done" o regresar a la anterior.
  def sync_column_with_status
    return unless status_changed?
    return if column_id_changed? # ya se está moviendo manualmente
    return if column.blank?

    board = column.board
    if status == "done"
      done_column = board.columns.find_by(kind: "done")
      return if done_column.nil? || done_column.id == column_id
      self.column = done_column
      self.position = done_column.tasks.count
    elsif column.kind == "done"
      previous = board.columns
                      .where.not(kind: "done")
                      .where("position < ?", column.position)
                      .reorder(position: :desc)
                      .first
      previous ||= board.columns.where.not(kind: "done").reorder(position: :desc).first
      return if previous.nil?
      self.column = previous
      self.position = previous.tasks.count
    end
  end

  def sync_publication
    publication&.update(title: title, publication_date: due_date, description: notes)
  end
end
