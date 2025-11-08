class AddInvitationTokenToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :invitation_token, :string
    add_index :projects, :invitation_token, unique: true
  end
end
