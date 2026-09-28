Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "organizations#index"

  resources :organizations do
    resource :spreadsheet_connection, only: %i[new create destroy]

    resources :areas, except: %i[index show] do
      resource :spreadsheet_connection, only: %i[new create destroy]
      resources :forms, only: %i[index new create]
    end
  end

  resources :forms, only: %i[show edit update destroy] do
    member do
      patch :publish
      patch :close
      get :preview
      post :sync
    end

    resource :spreadsheet_connection, only: %i[new create destroy]

    resources :form_fields, path: "fields", except: %i[index show] do
      member do
        patch :move_up
        patch :move_down
      end
    end
  end

  get  "f/:public_id",         to: "public_forms#show",   as: :public_form
  post "f/:public_id",         to: "public_forms#create"
  get  "f/:public_id/gracias", to: "public_forms#thanks", as: :public_form_thanks
end
