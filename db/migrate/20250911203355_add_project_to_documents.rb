class AddProjectToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_reference :documents, :project, null: false, foreign_key: true
  end
end
