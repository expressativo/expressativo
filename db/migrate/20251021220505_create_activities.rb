class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :trackable, polymorphic: true, null: false
      t.string :action, null: false
      t.json :metadata

      t.timestamps
    end

    add_index :activities, [:project_id, :created_at]
    add_index :activities, [:trackable_type, :trackable_id]
  end
end
