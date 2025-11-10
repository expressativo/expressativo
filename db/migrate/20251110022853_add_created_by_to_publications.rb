class AddCreatedByToPublications < ActiveRecord::Migration[8.0]
  def change
    # Agregar la columna created_by_id si no existe (para producción)
    unless column_exists?(:publications, :created_by_id)
      add_reference :publications, :created_by, null: true, foreign_key: { to_table: :users }
    end
  end
end
