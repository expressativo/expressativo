class CreatePublications < ActiveRecord::Migration[8.0]
  def change
    create_table :publications do |t|
      t.string :title
      t.text :description
      t.date :publication_date
      t.references :project, null: false, foreign_key: true
      t.references :task, null: true, foreign_key: true

      t.timestamps
    end
  end
end
