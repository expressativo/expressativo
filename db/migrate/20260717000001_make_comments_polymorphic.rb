class MakeCommentsPolymorphic < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:comments, :commentable_type)
      add_column :comments, :commentable_type, :string
    end
    unless column_exists?(:comments, :commentable_id)
      add_column :comments, :commentable_id, :bigint
    end

    # Backfill: convertir los comentarios existentes (todos de Task) al esquema polimórfico
    execute <<~SQL.squish
      UPDATE comments
      SET commentable_type = 'Task',
          commentable_id = task_id
      WHERE task_id IS NOT NULL
        AND commentable_id IS NULL
    SQL

    change_column_null :comments, :commentable_type, false
    change_column_null :comments, :commentable_id, false

    unless index_exists?(:comments, %i[commentable_type commentable_id], name: "index_comments_on_commentable")
      add_index :comments, %i[commentable_type commentable_id], name: "index_comments_on_commentable"
    end

    # Eliminar FK + índice + columna de task_id (en este orden por las constraints de MySQL)
    if foreign_key_exists?(:comments, :tasks)
      remove_foreign_key :comments, :tasks
    end
    if index_exists?(:comments, :task_id, name: "index_comments_on_task_id")
      remove_index :comments, name: "index_comments_on_task_id"
    end
    if column_exists?(:comments, :task_id)
      remove_column :comments, :task_id
    end
  end

  def down
    add_column :comments, :task_id, :bigint
    execute <<~SQL.squish
      UPDATE comments
      SET task_id = commentable_id
      WHERE commentable_type = 'Task'
    SQL
    change_column_null :comments, :task_id, false
    add_index :comments, :task_id, name: "index_comments_on_task_id" unless index_exists?(:comments, :task_id, name: "index_comments_on_task_id")
    add_foreign_key :comments, :tasks unless foreign_key_exists?(:comments, :tasks)

    remove_index :comments, name: "index_comments_on_commentable" if index_exists?(:comments, %i[commentable_type commentable_id], name: "index_comments_on_commentable")
    remove_column :comments, :commentable_type if column_exists?(:comments, :commentable_type)
    remove_column :comments, :commentable_id if column_exists?(:comments, :commentable_id)
  end
end
