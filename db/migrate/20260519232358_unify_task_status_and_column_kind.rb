class UnifyTaskStatusAndColumnKind < ActiveRecord::Migration[8.0]
  TODO_NAME_PATTERN = /\A(por hacer|to ?do|pendiente|backlog|nuevo)/i
  IN_PROGRESS_NAME_PATTERN = /\A(en progreso|in ?progress|doing|haciendo|trabajando)/i
  DONE_NAME_PATTERN = /\A(completad|hecho|done|listo|terminad|finalizad|cerrad)/i

  def up
    unless column_exists?(:tasks, :status)
      add_column :tasks, :status, :string, default: "pending", null: false
    end
    add_index :tasks, :status unless index_exists?(:tasks, :status)

    unless column_exists?(:columns, :kind)
      add_column :columns, :kind, :string, default: "custom", null: false
    end
    add_index :columns, [ :board_id, :kind ] unless index_exists?(:columns, [ :board_id, :kind ])

    if column_exists?(:tasks, :done)
      backfill_task_status
    end

    backfill_column_kind_and_positions
    ensure_required_columns_per_board

    remove_column :tasks, :done if column_exists?(:tasks, :done)
  end

  def down
    add_column :tasks, :done, :boolean, default: false, null: false unless column_exists?(:tasks, :done)
    execute "UPDATE tasks SET done = (status = 'done')"

    remove_index :columns, [ :board_id, :kind ] if index_exists?(:columns, [ :board_id, :kind ])
    remove_column :columns, :kind if column_exists?(:columns, :kind)

    remove_index :tasks, :status if index_exists?(:tasks, :status)
    remove_column :tasks, :status if column_exists?(:tasks, :status)
  end

  private

  def backfill_task_status
    execute "UPDATE tasks SET status = 'done' WHERE done = TRUE"
    execute "UPDATE tasks SET status = 'pending' WHERE done = FALSE"
  end

  def backfill_column_kind_and_positions
    board_ids = select_values("SELECT id FROM #{quote_table_name('boards')}")
    board_ids.each do |board_id|
      rows = select_all(
        "SELECT id, title, position FROM #{quote_table_name('columns')} " \
        "WHERE board_id = #{quote(board_id)} ORDER BY position ASC, id ASC"
      ).to_a

      next if rows.empty?

      done_col = rows.find { |c| c["title"].to_s.match?(DONE_NAME_PATTERN) } || rows.last
      remaining = rows.reject { |c| c["id"] == done_col["id"] }
      todo_col = remaining.find { |c| c["title"].to_s.match?(TODO_NAME_PATTERN) } || remaining.first

      remaining.each do |col|
        kind =
          if todo_col && col["id"] == todo_col["id"]
            "todo"
          elsif col["title"].to_s.match?(IN_PROGRESS_NAME_PATTERN)
            "in_progress"
          else
            "custom"
          end
        update_column_record(col["id"], kind: kind)
      end

      update_column_record(done_col["id"], kind: "done")

      ordered = remaining + [ done_col ]
      ordered.each_with_index do |col, idx|
        update_column_record(col["id"], position: idx)
      end
    end
  end

  def ensure_required_columns_per_board
    board_ids = select_values("SELECT id FROM #{quote_table_name('boards')}")
    board_ids.each do |board_id|
      rows = select_all(
        "SELECT id, title, position, kind FROM #{quote_table_name('columns')} " \
        "WHERE board_id = #{quote(board_id)} ORDER BY position ASC, id ASC"
      ).to_a

      has_done = rows.any? { |c| c["kind"] == "done" }
      has_todo = rows.any? { |c| c["kind"] == "todo" }

      unless has_todo
        execute(
          "UPDATE #{quote_table_name('columns')} SET position = position + 1 " \
          "WHERE board_id = #{quote(board_id)}"
        )
        insert_column(board_id: board_id, title: "Por hacer", position: 0, kind: "todo")
      end

      unless has_done
        max_pos = select_value(
          "SELECT MAX(position) FROM #{quote_table_name('columns')} WHERE board_id = #{quote(board_id)}"
        ).to_i
        insert_column(board_id: board_id, title: "Completado", position: max_pos + 1, kind: "done")
      end
    end
  end

  def update_column_record(id, attrs)
    set_clause = attrs.map { |k, v| "#{quote_column_name(k)} = #{quote(v)}" }.join(", ")
    execute(
      "UPDATE #{quote_table_name('columns')} SET #{set_clause}, updated_at = #{db_now} " \
      "WHERE id = #{quote(id)}"
    )
  end

  def insert_column(board_id:, title:, position:, kind:)
    now = db_now
    execute(
      "INSERT INTO #{quote_table_name('columns')} (title, position, board_id, kind, created_at, updated_at) " \
      "VALUES (#{quote(title)}, #{quote(position)}, #{quote(board_id)}, #{quote(kind)}, #{now}, #{now})"
    )
  end

  def db_now
    quote(Time.current.utc.strftime("%Y-%m-%d %H:%M:%S"))
  end
end
