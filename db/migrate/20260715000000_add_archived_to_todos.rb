class AddArchivedToTodos < ActiveRecord::Migration[8.0]
  def change
    add_column :todos, :archived, :boolean, default: false, null: false
  end
end
