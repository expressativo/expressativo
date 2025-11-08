class AddColumnToTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :tasks, :column, null: true, foreign_key: true
    add_column :tasks, :position, :integer, default: 0
  end
end
