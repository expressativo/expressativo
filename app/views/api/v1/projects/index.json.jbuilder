json.array! @projects do |project|
  json.call(project, :id, :title, :description, :archived)
  json.todos_count project.todos.active.count
  json.tasks_count Task.joins(:todo).where(todos: { project_id: project.id }).count
end
