class MigratePublicationsToTasksAndDropTable < ActiveRecord::Migration[8.0]
  class LegacyPublication < ActiveRecord::Base
    self.table_name = "publications"
  end

  def up
    LegacyPublication.where(task_id: nil).find_each do |pub|
      next if pub.created_by_id.blank? || pub.project_id.blank? || pub.title.blank?

      todo = Todo.find_or_create_by(project_id: pub.project_id, name: "Publicaciones")

      task = todo.tasks.create!(
        title: pub.title,
        created_by_id: pub.created_by_id,
        due_date: pub.publication_date
      )

      task.update!(notes: pub.description) if pub.description.present?
    end

    drop_table :publications
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
