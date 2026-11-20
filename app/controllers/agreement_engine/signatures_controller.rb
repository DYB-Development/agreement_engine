# frozen_string_literal: true

module AgreementEngine
  class SignaturesController < ::ApplicationController
    skip_before_action :require_accepted_agreements!, raise: false
    before_action :require_signed_in
    before_action :set_type_and_version
    before_action :require_consent

    layout "agreement_engine/minimal"

    def show
    end

    def update
      if typed_name.blank?
        @error = t("agreement_engine.signatures.update.blank")
        render :show, status: :unprocessable_entity
      else
        redirect_to main_app.root_path, status: :see_other
      end
    end

    private

    def typed_name
      params.dig(:signature, :typed_name).to_s.strip
    end

    def signer
      AgreementEngine.config.current_user(self)
    end

    def require_signed_in
      redirect_to main_app.root_path unless AgreementEngine.config.signed_in?(self)
    end

    def require_consent
      return if signer.holds_consent?

      session[:agreement_engine_after_consent] = agreement_engine.signature_path(@type.key)
      redirect_to agreement_engine.consent_path
    end

    def set_type_and_version
      @type = AgreementEngine.document_type(params[:document_type])
      @version = @type&.signature? && AgreementEngine::Document.current(@type.key)
      redirect_to main_app.root_path unless @version
    end
  end
end
