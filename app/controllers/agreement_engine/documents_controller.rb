# frozen_string_literal: true

module AgreementEngine
  class DocumentsController < ::ApplicationController
    def show
      @type = AgreementEngine.document_type(params[:document_type])
      return head(:not_found) unless @type&.standing?

      @version = AgreementEngine::Document.current(@type.key)
    end
  end
end
