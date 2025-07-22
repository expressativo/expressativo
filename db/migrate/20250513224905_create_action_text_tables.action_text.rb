# This migration comes from action_text (originally 20180528164100)
class CreateActionTextTables < ActiveRecord::Migration[6.0]
  def up
    # Desactivar verificación de claves foráneas para MySQL
    if connection.adapter_name.downcase.starts_with?("mysql")
      execute("SET FOREIGN_KEY_CHECKS=0;")
    end

    # Use Active Record's configured type for primary and foreign keys
    primary_key_type, foreign_key_type = primary_and_foreign_key_types

    # Verificar si la tabla ya existe antes de crearla
    unless table_exists?(:action_text_rich_texts)
      create_table :action_text_rich_texts, id: primary_key_type do |t|
        t.string     :name, null: false
        t.text       :body, size: :long
        t.references :record, null: false, polymorphic: true, index: false, type: foreign_key_type

        t.timestamps

        t.index [ :record_type, :record_id, :name ], name: "index_action_text_rich_texts_uniqueness", unique: true
      end
    end

    # Reactivar verificación de claves foráneas para MySQL
    if connection.adapter_name.downcase.starts_with?("mysql")
      execute("SET FOREIGN_KEY_CHECKS=1;")
    end
  end

  def down
    # Desactivar verificación de claves foráneas para MySQL
    if connection.adapter_name.downcase.starts_with?("mysql")
      execute("SET FOREIGN_KEY_CHECKS=0;")
    end

    drop_table :action_text_rich_texts if table_exists?(:action_text_rich_texts)

    # Reactivar verificación de claves foráneas para MySQL
    if connection.adapter_name.downcase.starts_with?("mysql")
      execute("SET FOREIGN_KEY_CHECKS=1;")
    end
  end

  private
    def primary_and_foreign_key_types
      config = Rails.configuration.generators
      setting = config.options[config.orm][:primary_key_type]
      primary_key_type = setting || :primary_key
      foreign_key_type = setting || :bigint
      [ primary_key_type, foreign_key_type ]
    end
end
