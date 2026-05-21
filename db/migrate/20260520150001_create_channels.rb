class CreateChannels < ActiveRecord::Migration[8.0]
  def change
    create_table :channels do |t|
      t.references :project, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :kind, null: false, default: "public"
      t.datetime :archived_at
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :channels, [ :project_id, :slug ], unique: true
    add_index :channels, [ :project_id, :name ], unique: true
  end
end
