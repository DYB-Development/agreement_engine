Rails.application.routes.draw do
  mount AgreementEngine::Engine, at: "/"

  root to: "home#index"

  post "test_sign_in", to: "sessions#create"
  get "opened_checks/:document_type", to: "opened_checks#show", as: :opened_check
end
