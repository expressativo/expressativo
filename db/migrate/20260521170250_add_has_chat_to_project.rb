class AddHasChatToProject < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :has_chat, :boolean, default: true, null: false
  end
end
