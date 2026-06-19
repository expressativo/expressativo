class CreateTaskCustomFieldValues < ActiveRecord::Migration[8.0]
  def change
    create_table :task_custom_field_values do |t|
      t.references :task, null: false, foreign_key: true
      t.references :project_custom_field, null: false, foreign_key: true
      t.text :value

      t.timestamps
    end

    add_index :task_custom_field_values, [ :task_id, :project_custom_field_id ],
              unique: true,
              name: "index_task_custom_field_values_uniqueness"
  end
end
