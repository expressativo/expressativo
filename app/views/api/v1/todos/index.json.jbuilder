json.array! @todos do |todo|
  json.call(todo, :id, :name, :archived)
  json.project_id todo.project_id
  json.tasks_count todo.tasks.count
end
