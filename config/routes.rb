Rails.application.routes.draw do
  root "organizations#index"

  resources :organizations do
    resource :spreadsheet_connection, only: %i[new create destroy]

    resources :areas, except: %i[index show] do
      resource :spreadsheet_connection, only: %i[new create destroy]
    end
  end
end
