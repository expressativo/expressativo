class CreateMessageReactions < ActiveRecord::Migration[8.0]
  def change
    create_table :message_reactions do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :emoji, null: false, limit: 16

      t.timestamps
    end

    add_index :message_reactions, [ :message_id, :user_id, :emoji ], unique: true, name: "idx_message_reactions_unique"
  end
end
