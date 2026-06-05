class AddListPositionToTasks < ActiveRecord::Migration[8.0]
  def up
    add_column :tasks, :list_position, :integer, default: 0
    add_index :tasks, [ :todo_id, :list_position ]

    Task.reset_column_information
    Task.find_each do |task|
      task.update_column(:list_position, task.position || 0)
    end
  end

  def down
    remove_index :tasks, [ :todo_id, :list_position ]
    remove_column :tasks, :list_position
  end
end
