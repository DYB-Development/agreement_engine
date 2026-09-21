# frozen_string_literal: true

module AgreementEngine
  class DocumentsController < ::ApplicationController
    def terms
      @agreement = AgreementEngine.config.agreements.find { |a| a.id == :terms_of_service }
      @version = AgreementEngine::Document.current(:terms_of_service)
    end

    def privacy
      @agreement = AgreementEngine.config.agreements.find { |a| a.id == :privacy_policy }
      @version = AgreementEngine::Document.current(:privacy_policy)
    end
  end
end
