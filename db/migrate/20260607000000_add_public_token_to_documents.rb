class AddPublicTokenToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :public_token, :string
    add_column :documents, :published_publicly_at, :datetime
    add_index :documents, :public_token, unique: true
  end
end
