class CreateFolders < ActiveRecord::Migration[8.0]
  def change
    create_table :folders do |t|
      t.string :name, null: false
      t.references :project, null: false, foreign_key: true
      t.references :parent_folder, null: true, foreign_key: { to_table: :folders }
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :folders, [:project_id, :name]
  end
end
