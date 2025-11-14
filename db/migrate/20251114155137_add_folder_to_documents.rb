class AddFolderToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_reference :documents, :folder, null: true, foreign_key: true, index: true
  end
end
