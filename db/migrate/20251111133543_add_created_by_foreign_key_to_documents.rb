class AddCreatedByForeignKeyToDocuments < ActiveRecord::Migration[8.0]
  def change
    # Rename the column to follow Rails conventions (created_by instead of create_by)
    # Only rename if the old column exists and the new one doesn't
    if column_exists?(:documents, :create_by_id) && !column_exists?(:documents, :created_by_id)
      rename_column :documents, :create_by_id, :created_by_id
    end

    # Add the column if it doesn't exist at all
    unless column_exists?(:documents, :created_by_id)
      add_column :documents, :created_by_id, :bigint, null: false
    end

    # Fix orphaned records: assign them to the first user
    reversible do |dir|
      dir.up do
        first_user_id = select_value("SELECT id FROM users ORDER BY id LIMIT 1")

        # If there are no users yet, skip the backfill step
        if first_user_id
          execute("UPDATE documents SET created_by_id = #{first_user_id} WHERE created_by_id NOT IN (SELECT id FROM users)")
        end
      end
    end

    # Add the foreign key constraint to users table
    add_foreign_key :documents, :users, column: :created_by_id unless foreign_key_exists?(:documents, :users, column: :created_by_id)
  end
end
