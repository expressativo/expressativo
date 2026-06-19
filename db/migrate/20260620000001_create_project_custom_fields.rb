class CreateProjectCustomFields < ActiveRecord::Migration[8.0]
  def change
    create_table :project_custom_fields do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :field_type, null: false, default: "text"
      t.text :options
      t.integer :position, default: 0, null: false
      t.string :key, null: true

      t.timestamps
    end

    add_index :project_custom_fields, [ :project_id, :position ]
  end
end
