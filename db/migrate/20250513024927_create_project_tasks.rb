class CreateProjectTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :project_tasks do |t|
      t.timestamps
    end
  end
end
