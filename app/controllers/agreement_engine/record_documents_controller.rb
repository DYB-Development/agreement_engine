# frozen_string_literal: true

module AgreementEngine
  class RecordDocumentsController < SignaturesController
    def update
      return super if @type.signature?

      if too_soon?
        @error = too_soon_reason(:accepting)
        return render(:show, status: :unprocessable_entity)
      end

      AgreementEngine::Acceptance.record!(
        signer: signer,
        document: @version,
        request: request,
        statement: t("agreement_engine.record_documents.show.statement", document: @type.title),
        button_text: t("agreement_engine.record_documents.show.accept"),
        evidence: AgreementEngine.config.evidence(self, signer),
        reading: reading_evidence
      )
      redirect_to after_signing_path, status: :see_other, notice: t("agreement_engine.record_documents.update.accepted", document: @type.title)
    end

    private

    def require_consent
      super if @type.signature?
    end

    def set_type_and_version
      @version = AgreementEngine::Document.where.not(subject_id: nil).find_by(code: params[:code])
      @type = @version && AgreementEngine.document_type(@version.document_type)
      head :not_found unless @type && AgreementEngine.config.may_sign?(self, signer, @version)
    end

    def current_version
      AgreementEngine.current_for(@type.key, @version.subject)
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
