class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :messageable, polymorphic: true, null: false, index: false
      t.references :user, null: false, foreign_key: true
      t.references :parent_message, null: true, foreign_key: { to_table: :messages }
      t.text :body, null: false
      t.datetime :edited_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :messages, [ :messageable_type, :messageable_id, :created_at ], name: "index_messages_on_messageable_and_created_at"
    add_index :messages, [ :parent_message_id, :created_at ]
  end
end
