class MigrateExisintingProjectsToProjectUsers < ActiveRecord::Migration[8.0]
    def up
      Project.find_each do |project|
        if project.user_id.present?
          ProjectUser.create!(
            project_id: project.id,
            user_id: project.user_id,
            role: 'owner'
          )
        end
      end
    end

    def down
      ProjectUser.destroy_all
    end
end
