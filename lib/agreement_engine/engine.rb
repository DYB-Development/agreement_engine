# frozen_string_literal: true

require_relative "pages_elements"

module AgreementEngine
  class Engine < ::Rails::Engine
    isolate_namespace AgreementEngine

    initializer "agreement_engine.pages_elements" do
      AgreementEngine::PagesElements.register(KeystoneUi::Pages.catalog)
      ActiveSupport.on_load(:action_view) { include AgreementEngine::PagesElements::Drawing }
    end
  end
end
