class CreateProjectUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :project_users do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, default: 'member', null: false

      t.timestamps
    end
  end
end
