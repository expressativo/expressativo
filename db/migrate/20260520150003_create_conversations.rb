class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user_one, null: false, foreign_key: { to_table: :users }
      t.references :user_two, null: false, foreign_key: { to_table: :users }
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, [ :project_id, :user_one_id, :user_two_id ], unique: true, name: "index_conversations_on_project_and_users"
  end
end
