class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.string :content
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
