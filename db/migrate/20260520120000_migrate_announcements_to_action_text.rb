class MigrateAnnouncementsToActionText < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
      SELECT
        'content' as name,
        a.content as body,
        'Announcement' as record_type,
        a.id as record_id,
        NOW() as created_at,
        NOW() as updated_at
      FROM announcements a
      WHERE a.content IS NOT NULL
        AND a.content != ''
        AND NOT EXISTS (
          SELECT 1
          FROM action_text_rich_texts art
          WHERE art.record_type = 'Announcement'
            AND art.record_id = a.id
            AND art.name = 'content'
        )
    SQL
  end

  def down
    execute <<-SQL
      UPDATE announcements a
      INNER JOIN action_text_rich_texts art
        ON art.record_type = 'Announcement'
        AND art.record_id = a.id
        AND art.name = 'content'
      SET a.content = art.body
      WHERE art.body IS NOT NULL
    SQL

    execute <<-SQL
      DELETE FROM action_text_rich_texts
      WHERE record_type = 'Announcement'
        AND name = 'content'
    SQL
  end
end
