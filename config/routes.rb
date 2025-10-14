Rails.application.routes.draw do
  devise_for :users

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :projects do
    resources :documents, only: %i[index new create]
    resources :todos do
      resources :tasks do
        member do
          post :add_comment
        end
      end
      member do
        get :completed_tasks, to: "todos#completed_tasks"
      end
    end
    resources :announcements do
      resources :announcement_comments
    end
    resources :members, controller: "project_members", only: %i[index new create destroy]
  end

  resources :documents, only: %i[show edit update destroy] do
    member do
      get :download
      post :duplicate
      patch :archive
    end
  end
  # resources :registers, only: %i[new create]
  root to: "projects#index"
end
