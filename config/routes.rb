Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Perfil de usuario
  resource :profile, only: [ :show, :edit, :update ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :projects do
    resources :folders do
      resources :documents, only: %i[new create]
    end
    resources :documents, only: %i[index new create]
    resources :todos do
      resources :tasks do
        member do
          post :add_comment
          get :search_members
        end
        resources :assignments, controller: "task_assignments", only: [ :create, :destroy ] do
          collection do
            get :search
          end
        end
        resources :comments, only: [ :edit, :update, :destroy ]
      end
      member do
        get :completed_tasks, to: "todos#completed_tasks"
      end
    end
    resources :announcements do
      resources :announcement_comments
    end
    resources :members, controller: "project_members", only: %i[index new create destroy]
    resource :timeline, only: [ :show ], controller: "timelines"

    # Tableros Kanban
    resources :boards do
      member do
        get :add_tasks
      end
      collection do
        post :attach_task
        post :attach_multiple_tasks
      end
      resources :columns, only: [ :create, :update, :destroy ] do
        member do
          patch :update_position
        end
      end
    end

    # Calendario de Publicaciones
    resources :publications do
      member do
        patch :update_date
      end
    end

    member do
      post :regenerate_invitation, to: "project_invitations#regenerate"
      patch :archive
      patch :unarchive
    end
  end

  # Proyectos archivados
  get "archived_projects", to: "projects#archived", as: :archived_projects

  # Rutas para actualizar posición de tareas en tableros
  resources :board_tasks, only: [] do
    member do
      patch :update_position
      post :add_to_board
      delete :remove_from_board
    end
  end

  # Ruta para ver tareas asignadas al usuario actual
  get "my_task", to: "tasks#my_task", as: :my_task

  # Rutas de invitación (fuera del namespace de projects para URLs más limpias)
  get "invite/:token", to: "project_invitations#show", as: :project_invitation
  post "invite/:token/accept", to: "project_invitations#accept", as: :accept_project_invitation

  resources :documents, only: %i[show edit update destroy] do
    member do
      get :download
      post :duplicate
      patch :archive
    end
  end

  # Notificaciones
  resources :notifications, only: [ :index, :show ] do
    member do
      post :mark_as_read
    end
    collection do
      post :mark_all_as_read
      get :unread_count
    end
  end

  # resources :registers, only: %i[new create]
  root to: "home#index"
end
