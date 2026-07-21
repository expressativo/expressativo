json.id               task.id
json.todo_id          task.todo_id
json.title            task.title
json.status           task.status
json.completed        task.status == "done"
json.notes            task.notes&.body&.to_plain_text.to_s.strip
json.due_date         task.due_date&.iso8601
json.position         task.list_position
json.public_token     task.public_token
json.created_at       task.created_at.iso8601
json.updated_at       task.updated_at.iso8601
