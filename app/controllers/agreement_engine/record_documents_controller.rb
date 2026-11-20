# frozen_string_literal: true

module AgreementEngine
  class RecordDocumentsController < SignaturesController
    private

    def set_type_and_version
      @version = AgreementEngine::Document.where.not(subject_id: nil).find_by(code: params[:code])
      @type = @version && AgreementEngine.document_type(@version.document_type)
      head :not_found unless @type && AgreementEngine.config.may_sign?(self, signer, @version)
    end

    def form_url
      agreement_engine.record_document_path(@version, return_to: return_path)
    end

    def after_signing_path
      return_path || super
    end

    def return_path
      AgreementEngine.config.allowed_return_path(params[:return_to])
    end
  end
end
