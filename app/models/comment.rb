class Comment < ApplicationRecord
  include TrackableActivity

  belongs_to :task
  belongs_to :user

  has_rich_text :content

  private

  def get_project
    task.todo.project
  end
end
