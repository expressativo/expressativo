class AddPublicTokenToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :public_token, :string
    add_column :tasks, :published_publicly_at, :datetime
    add_index :tasks, :public_token, unique: true
  end
end
