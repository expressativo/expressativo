class Publication < ApplicationRecord
  belongs_to :project
  belongs_to :task, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validates :title, presence: true
  validates :publication_date, presence: true

  after_create :create_associated_task
  after_update :sync_task_title, if: :saved_change_to_title?

  scope :for_month, ->(year, month) {
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(publication_date: start_date..end_date)
  }

  private

  def create_associated_task
    return if task.present? || created_by.blank?

    # Buscar o crear la todo list "Publicaciones"
    todo = project.todos.find_or_create_by(name: "Publicaciones")

    # Crear la tarea
    new_task = todo.tasks.create(
      title: title,
      created_by: created_by,
      done: false,
      due_date: publication_date,
    )

    # Agregar la descripción como notes si existe
    new_task.update(notes: description) if description.present? && new_task.persisted?

    # Asociar la tarea a la publicación
    update_column(:task_id, new_task.id) if new_task.persisted?
  end

  def sync_task_title
    task&.update_column(:title, title)
  end
end
