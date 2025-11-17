class MigrateDocumentBodyToActionText < ActiveRecord::Migration[8.0]
  def up
    # Migrar datos de documents.body a action_text_rich_texts
    # Solo para documentos que tienen body pero no tienen action_text_rich_texts

    execute <<-SQL
      INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
      SELECT
        'body' as name,
        d.body as body,
        'Document' as record_type,
        d.id as record_id,
        NOW() as created_at,
        NOW() as updated_at
      FROM documents d
      WHERE d.body IS NOT NULL
        AND d.body != ''
        AND NOT EXISTS (
          SELECT 1
          FROM action_text_rich_texts art
          WHERE art.record_type = 'Document'
            AND art.record_id = d.id
            AND art.name = 'body'
        )
    SQL

    puts "Migrated #{Document.where.not(body: [nil, '']).count} document bodies to Action Text"
  end

  def down
    # Revertir copiando de action_text_rich_texts a documents.body
    execute <<-SQL
      UPDATE documents d
      INNER JOIN action_text_rich_texts art
        ON art.record_type = 'Document'
        AND art.record_id = d.id
        AND art.name = 'body'
      SET d.body = art.body
      WHERE art.body IS NOT NULL
    SQL

    # Eliminar los registros de action_text_rich_texts para documentos
    execute <<-SQL
      DELETE FROM action_text_rich_texts
      WHERE record_type = 'Document'
        AND name = 'body'
    SQL

    puts "Reverted Action Text bodies back to documents.body column"
  end
end
