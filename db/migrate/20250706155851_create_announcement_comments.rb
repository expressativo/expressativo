class CreateAnnouncementComments < ActiveRecord::Migration[8.0]
  def change
    create_table :announcement_comments do |t|
      t.text :content
      t.references :announcement, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
