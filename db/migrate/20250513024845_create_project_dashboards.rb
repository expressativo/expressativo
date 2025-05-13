class CreateProjectDashboards < ActiveRecord::Migration[8.0]
  def change
    create_table :project_dashboards do |t|
      t.timestamps
    end
  end
end
