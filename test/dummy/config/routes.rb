Rails.application.routes.draw do
  mount AgreementEngine::Engine, at: "/"

  root to: "home#index"

  post "test_sign_in", to: "sessions#create"
end
