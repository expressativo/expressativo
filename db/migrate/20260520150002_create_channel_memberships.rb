class CreateChannelMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :channel_memberships do |t|
      t.references :channel, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :last_read_at
      t.string :notifications_setting, null: false, default: "all"
      t.datetime :muted_until

      t.timestamps
    end

    add_index :channel_memberships, [ :channel_id, :user_id ], unique: true
    add_index :channel_memberships, [ :user_id, :last_read_at ]
  end
end
