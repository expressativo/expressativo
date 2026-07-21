json.call(@project, :id, :title, :description, :archived)
json.todos @project.todos.active.order(:name) do |todo|
  json.call(todo, :id, :name, :archived)
  json.tasks_count todo.tasks.count
end
