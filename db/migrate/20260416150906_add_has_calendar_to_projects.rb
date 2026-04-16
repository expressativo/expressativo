class AddHasCalendarToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :has_calendar, :boolean
  end
end
