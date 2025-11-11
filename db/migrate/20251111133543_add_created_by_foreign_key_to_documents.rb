class AddCreatedByForeignKeyToDocuments < ActiveRecord::Migration[8.0]
  def change
    # Rename the column to follow Rails conventions (created_by instead of create_by)
    rename_column :documents, :create_by_id, :created_by_id unless column_exists?(:documents, :created_by_id)

    # Fix orphaned records: assign them to the first user
    reversible do |dir|
      dir.up do
        result = execute("SELECT id FROM users ORDER BY id LIMIT 1")
        first_user_id = result.first[0]
        execute("UPDATE documents SET created_by_id = #{first_user_id} WHERE created_by_id NOT IN (SELECT id FROM users)")
      end
    end

    # Add the foreign key constraint to users table
    add_foreign_key :documents, :users, column: :created_by_id unless foreign_key_exists?(:documents, :users, column: :created_by_id)
  end
end
