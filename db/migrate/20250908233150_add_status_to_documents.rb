class AddStatusToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :status, :string, default: "draft", null: false
    add_index :documents, :status
  end
end
