# frozen_string_literal: true

require_relative "pages_elements"

module AgreementEngine
  class Engine < ::Rails::Engine
    isolate_namespace AgreementEngine

    initializer "agreement_engine.pages_elements" do
      AgreementEngine::PagesElements.register(KeystoneUi::Pages.catalog)
      ActiveSupport.on_load(:action_view) { include AgreementEngine::PagesElements::Drawing }
    end

    initializer "agreement_engine.url_helpers" do
      ActiveSupport.on_load(:action_controller) do
        helper Rails.application.routes.url_helpers
      end
    end
  end
end
