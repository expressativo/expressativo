class CreateQuickNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :quick_notes do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :color, default: "yellow"
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :quick_notes, [ :user_id, :position ]
  end
end
