Rails.application.routes.draw do
  root "organizations#index"

  resources :organizations do
    resources :areas, except: %i[index show]
  end
end
