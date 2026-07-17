module CommentsHelper
  # Etiqueta legible para el tipo de commentable (en minúscula, con artículo).
  # Ej.: "la tarea", "el documento".
  def commentable_label(commentable)
    case commentable
    when Task then "la tarea"
    when Document then "el documento"
    else "el recurso"
    end
  end

  # Título o nombre del commentable.
  def commentable_title(commentable)
    commentable.respond_to?(:title) ? commentable.title : commentable.name
  end

  # URL pública para ver el commentable.
  def commentable_url(commentable)
    case commentable
    when Task
      project_todo_task_url(commentable.todo.project, commentable.todo, commentable)
    when Document
      document_url(commentable)
    end
  end

  # Etiqueta del botón del email según el tipo de commentable.
  def commentable_button_label(commentable)
    case commentable
    when Task then "Ver tarea completa"
    when Document then "Ver documento completo"
    else "Ver recurso"
    end
  end

  # Ruta de edición/eliminación de un comentario según el contexto del commentable.
  # Devuelve nil si no se puede construir (porque faltan locals).
  def comment_edit_path(comment, commentable:)
    case commentable
    when Task
      edit_project_todo_task_comment_path(commentable.todo.project, commentable.todo, commentable, comment)
    when Document
      edit_document_comment_path(commentable, comment)
    end
  end

  def comment_update_path(comment, commentable:)
    case commentable
    when Task
      project_todo_task_comment_path(commentable.todo.project, commentable.todo, commentable, comment)
    when Document
      document_comment_path(commentable, comment)
    end
  end

  def comment_delete_path(comment, commentable:)
    case commentable
    when Task
      project_todo_task_comment_path(commentable.todo.project, commentable.todo, commentable, comment)
    when Document
      document_comment_path(commentable, comment)
    end
  end

  # Ruta POST para crear un comentario en este commentable.
  def comment_create_path(commentable)
    case commentable
    when Task
      add_comment_project_todo_task_path(commentable.todo.project, commentable.todo, commentable)
    when Document
      add_comment_document_path(commentable)
    end
  end

  # Ruta GET para el autocomplete de miembros (lexxy-prompt src).
  def comment_search_members_path(commentable)
    case commentable
    when Task
      search_members_project_todo_task_path(commentable.todo.project, commentable.todo, commentable)
    when Document
      search_members_document_path(commentable)
    end
  end

  # Ruta a la que volver después de operar con un comentario.
  def comment_back_path(commentable)
    case commentable
    when Task
      project_todo_task_path(commentable.todo.project, commentable.todo, commentable)
    when Document
      document_path(commentable)
    end
  end
end
