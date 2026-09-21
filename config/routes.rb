AgreementEngine::Engine.routes.draw do
  resources :agreements, only: [:show, :update, :destroy]

  get "terms", to: "documents#terms", as: :terms
  get "privacy", to: "documents#privacy", as: :privacy

  namespace :admin do
    resources :documents
  end
end
