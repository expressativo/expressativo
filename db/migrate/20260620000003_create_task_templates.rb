class CreateTaskTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :task_templates do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :title

      t.timestamps
    end
  end
end
