# frozen_string_literal: true

module AgreementEngine
  class ConsentsController < ::ApplicationController
    skip_before_action :require_accepted_agreements!, raise: false
    before_action :require_signed_in
    before_action :set_version

    layout "agreement_engine/minimal"

    def show
    end

    def create
      AgreementEngine::Acceptance.record!(
        signer: signer,
        document: @version,
        request: request,
        statement: t("agreement_engine.consents.show.statement"),
        button_text: t("agreement_engine.consents.show.consent"),
        evidence: AgreementEngine.config.evidence(self, signer)
      )
      redirect_to agreement_engine.consent_path, status: :see_other, notice: t(".given")
    end

    private

    def signer
      AgreementEngine.config.current_user(self)
    end

    def require_signed_in
      redirect_to main_app.root_path unless AgreementEngine.config.signed_in?(self)
    end

    def set_version
      @version = AgreementEngine::Document.current(Consent::TYPE.key)
      redirect_to main_app.root_path unless @version
    end
  end
end
