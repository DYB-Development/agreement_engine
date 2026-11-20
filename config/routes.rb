AgreementEngine::Engine.routes.draw do
  resources :agreements, only: [:show, :update, :destroy]
  resource :consent, only: [:show, :create, :destroy]
  resource :verification, only: [:show, :create], path: "verify"
  resources :signatures, only: [:show, :update], param: :document_type
  resources :record_documents, only: [:show, :update], param: :code, path: "records"
  resources :receipts, only: [:show] do
    get :byte_form, on: :member
  end

  get "terms", to: "documents#terms", as: :terms
  get "privacy", to: "documents#privacy", as: :privacy

  namespace :admin do
    resources :documents
    resources :issues, only: [:new, :create]
  end
end
