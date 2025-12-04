class CreateCommentMentions < ActiveRecord::Migration[8.0]
  def change
    create_table :comment_mentions do |t|
      t.references :comment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :comment_mentions, [ :comment_id, :user_id ], unique: true
  end
end
