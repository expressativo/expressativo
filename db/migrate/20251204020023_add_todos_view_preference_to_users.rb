class AddTodosViewPreferenceToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :todos_view_preference, :string, default: "list"
  end
end
