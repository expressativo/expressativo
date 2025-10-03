class ForceRemoveUserIdFromProjects < ActiveRecord::Migration[8.0]
  def up
    if column_exists?(:projects, :user_id)
      remove_column :projects, :user_id
    end
  end

  def down
    # No hacer nada - no queremos restaurar la columna
  end
end
