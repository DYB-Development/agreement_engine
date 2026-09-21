# frozen_string_literal: true

module AgreementEngine
  class Engine < ::Rails::Engine
    isolate_namespace AgreementEngine

    initializer "agreement_engine.url_helpers" do
      ActiveSupport.on_load(:action_controller) do
        helper Rails.application.routes.url_helpers
      end
    end
  end
end
