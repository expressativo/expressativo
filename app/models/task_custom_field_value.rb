class TaskCustomFieldValue < ApplicationRecord
  belongs_to :task
  belongs_to :project_custom_field

  validates :task_id, uniqueness: { scope: :project_custom_field_id }
end
