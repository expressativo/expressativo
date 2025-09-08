class FixUserEmailColumns < ActiveRecord::Migration[8.0]
  def change
    # Si tienes datos en email_address, cópialos a email
    if column_exists?(:users, :email_address) && column_exists?(:users, :email)
      # Copia datos de email_address a email si email está vacío
      execute "UPDATE users SET email = email_address WHERE email IS NULL OR email = ''"

      # Elimina la columna email_address
      remove_column :users, :email_address
    end

    # Asegúrate de que email no pueda ser nulo
    change_column_null :users, :email, false if column_exists?(:users, :email)

    # Agrega índice único para email si no existe
    add_index :users, :email, unique: true unless index_exists?(:users, :email)
  end
end
