module TrackableActivity
  extend ActiveSupport::Concern

  included do
    after_create :log_created_activity
    after_update :log_updated_activity
    after_destroy :log_deleted_activity
  end

  private

  def log_created_activity
    return unless should_track_activity?

    action = is_comment? ? "commented" : "created"

    Activity.log(
      project: get_project,
      user: get_user,
      trackable: self,
      action: action,
      metadata: activity_metadata
    )
  end

  def log_updated_activity
    return unless should_track_activity?
    return if saved_changes.keys == ["updated_at"]

    action = determine_update_action
    Activity.log(
      project: get_project,
      user: get_user,
      trackable: self,
      action: action,
      metadata: activity_metadata
    )
  end

  def log_deleted_activity
    return unless should_track_activity?

    Activity.log(
      project: get_project,
      user: get_user,
      trackable: self,
      action: "deleted",
      metadata: activity_metadata
    )
  end

  def should_track_activity?
    get_project.present? && get_user.present?
  end

  def get_project
    return project if respond_to?(:project)
    return todo.project if respond_to?(:todo) && todo.present?
    return task.todo.project if respond_to?(:task) && task.present?
    return announcement.project if respond_to?(:announcement) && announcement.present?
    nil
  end

  def get_user
    Current.user
  end

  def activity_metadata
    metadata = {}
    metadata["title"] = title if respond_to?(:title)
    metadata["name"] = name if respond_to?(:name)

    if respond_to?(:content) && content.present?
      metadata["content"] = if content.respond_to?(:to_plain_text)
        content.to_plain_text.truncate(100)
      else
        content.to_s.truncate(100)
      end
    end

    metadata
  end

  def determine_update_action
    if respond_to?(:completed?) && saved_change_to_completed? && completed?
      "completed"
    elsif respond_to?(:status) && saved_change_to_status?
      status
    else
      "updated"
    end
  end

  def is_comment?
    self.class.name.include?("Comment")
  end
end
