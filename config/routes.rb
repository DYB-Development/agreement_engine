AgreementEngine::Engine.routes.draw do
  resources :agreements, only: [:show, :update, :destroy]
  resource :consent, only: [:show, :create, :destroy]
  resource :verification, only: [:show, :create], path: "verify"
  resources :signatures, only: [:show, :update], param: :document_type
  resources :record_documents, only: [:show, :update], param: :code, path: "records"
  resources :receipts, only: [:show] do
    get :byte_form, on: :member
  end

  get "terms", to: "documents#show", defaults: {document_type: "terms_of_service"}, as: :terms
  get "privacy", to: "documents#show", defaults: {document_type: "privacy_policy"}, as: :privacy
  get "documents/:document_type", to: "documents#show", as: :public_document

  namespace :admin do
    resources :documents, only: [:index, :show, :destroy]
    resources :issues, only: [:new, :create]
  end
end
