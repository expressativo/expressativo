class ChangeDoneInTasks < ActiveRecord::Migration[8.0]
  def change
    Task.where(done: nil).update_all(done: false)
    change_column_default :tasks, :done, from: nil, to: false
    change_column_null :tasks, :done, false
  end
end
