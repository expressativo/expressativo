class MigrateCommentsToActionText < ActiveRecord::Migration[8.0]
  def up
    # Migrar datos de comments.content a action_text_rich_texts
    execute <<-SQL
      INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
      SELECT
        'content' as name,
        c.content as body,
        'Comment' as record_type,
        c.id as record_id,
        NOW() as created_at,
        NOW() as updated_at
      FROM comments c
      WHERE c.content IS NOT NULL
        AND c.content != ''
        AND NOT EXISTS (
          SELECT 1
          FROM action_text_rich_texts art
          WHERE art.record_type = 'Comment'
            AND art.record_id = c.id
            AND art.name = 'content'
        )
    SQL

    # Migrar datos de announcement_comments.content a action_text_rich_texts
    execute <<-SQL
      INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
      SELECT
        'content' as name,
        ac.content as body,
        'AnnouncementComment' as record_type,
        ac.id as record_id,
        NOW() as created_at,
        NOW() as updated_at
      FROM announcement_comments ac
      WHERE ac.content IS NOT NULL
        AND ac.content != ''
        AND NOT EXISTS (
          SELECT 1
          FROM action_text_rich_texts art
          WHERE art.record_type = 'AnnouncementComment'
            AND art.record_id = ac.id
            AND art.name = 'content'
        )
    SQL
  end

  def down
    # Revertir comments
    execute <<-SQL
      UPDATE comments c
      INNER JOIN action_text_rich_texts art
        ON art.record_type = 'Comment'
        AND art.record_id = c.id
        AND art.name = 'content'
      SET c.content = art.body
      WHERE art.body IS NOT NULL
    SQL

    # Revertir announcement_comments
    execute <<-SQL
      UPDATE announcement_comments ac
      INNER JOIN action_text_rich_texts art
        ON art.record_type = 'AnnouncementComment'
        AND art.record_id = ac.id
        AND art.name = 'content'
      SET ac.content = art.body
      WHERE art.body IS NOT NULL
    SQL

    # Eliminar los registros de action_text_rich_texts
    execute <<-SQL
      DELETE FROM action_text_rich_texts
      WHERE record_type IN ('Comment', 'AnnouncementComment')
        AND name = 'content'
    SQL
  end
end
