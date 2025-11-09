class AddForeignKeyToPublicationsCreatedBy < ActiveRecord::Migration[8.0]
  def change
    # Cambiar la columna para permitir NULL
    change_column_null :publications, :created_by_id, true
    
    # Limpiar registros huérfanos (created_by_id que no existen en users)
    execute <<-SQL
      UPDATE publications 
      SET created_by_id = NULL 
      WHERE created_by_id IS NOT NULL 
      AND created_by_id NOT IN (SELECT id FROM users)
    SQL
    
    # Solo agregar el foreign key si no existe
    unless foreign_key_exists?(:publications, :users, column: :created_by_id)
      add_foreign_key :publications, :users, column: :created_by_id
    end
  end
end
