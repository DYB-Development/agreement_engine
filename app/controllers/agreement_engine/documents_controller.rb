# frozen_string_literal: true

module AgreementEngine
  class DocumentsController < ::ApplicationController
    def show
      @type = AgreementEngine.document_type(params[:document_type])
      return head(:not_found) unless @type&.standing?

      @version = AgreementEngine::Document.current(@type.key)
      record_opened if @version
    end

    private

    def record_opened
      opened = session[:agreement_engine_opened] ||= {}
      opened[@version.id.to_s] ||= Time.current.to_i
    end
  end
end
