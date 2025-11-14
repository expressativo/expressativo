class AddDocumentTypeToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :document_type, :string, null: false, default: "document"
    add_index :documents, :document_type
  end
end
