class Comment < ApplicationRecord
  include TrackableActivity

  belongs_to :task
  belongs_to :user

  private

  def get_project
    task.todo.project
  end
end
