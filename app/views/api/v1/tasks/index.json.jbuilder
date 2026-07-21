json.array! @tasks do |task|
  json.partial! "api/v1/tasks/task", task: task
end
