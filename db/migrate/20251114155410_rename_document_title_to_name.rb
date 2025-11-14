class RenameDocumentTitleToName < ActiveRecord::Migration[8.0]
  def change
    rename_column :documents, :title, :name
  end
end
