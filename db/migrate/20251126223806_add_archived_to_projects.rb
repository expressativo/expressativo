class AddArchivedToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :archived, :boolean, default: false, null: false
  end
end
