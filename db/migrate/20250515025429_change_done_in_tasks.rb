class ChangeDoneInTasks < ActiveRecord::Migration[8.0]
  def up
    # Usar SQL directo en lugar de modelos para mayor compatibilidad
    execute("UPDATE tasks SET done = FALSE WHERE done IS NULL")
    change_column_default :tasks, :done, from: nil, to: false
    change_column_null :tasks, :done, false
  end

  def down
    change_column_null :tasks, :done, true
    change_column_default :tasks, :done, from: false, to: nil
  end
end
