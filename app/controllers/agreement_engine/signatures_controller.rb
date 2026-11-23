# frozen_string_literal: true

module AgreementEngine
  class SignaturesController < ::ApplicationController
    skip_before_action :require_accepted_agreements!, raise: false
    before_action :require_signed_in
    before_action :set_type_and_version
    before_action :require_consent

    layout -> { AgreementEngine.config.layout }

    def show
      record_served
    end

    def update
      if stale?
        @error = t("agreement_engine.signatures.update.stale")
        @version = current_version
        render :show, status: :conflict
      elsif too_soon?
        @error = t("agreement_engine.signatures.update.too_soon", document: @type.title, seconds: @type.minimum_reading_seconds)
        render :show, status: :unprocessable_entity
      elsif already_signed?
        redirect_to after_signing_path, status: :see_other, notice: t("agreement_engine.signatures.update.signed", document: @type.title)
      elsif typed_name.blank?
        @error = t("agreement_engine.signatures.update.blank")
        render :show, status: :unprocessable_entity
      else
        AgreementEngine::Acceptance.record!(
          signer: signer,
          document: @version,
          request: request,
          statement: t("agreement_engine.signatures.show.statement", document: @type.title),
          button_text: t("agreement_engine.signatures.show.sign"),
          evidence: AgreementEngine.config.evidence(self, signer),
          signature: {strength: "signature", typed_name: typed_name, consent: signer.held_consent}
        )
        redirect_to after_signing_path, status: :see_other, notice: t("agreement_engine.signatures.update.signed", document: @type.title)
      end
    rescue ActiveRecord::RecordNotUnique
      redirect_to after_signing_path, status: :see_other, notice: t("agreement_engine.signatures.update.signed", document: @type.title)
    end

    private

    def record_served
      served = session[:agreement_engine_served] ||= {}
      served[@version.id.to_s] ||= Time.current.to_i
    end

    def too_soon?
      minimum = @type.minimum_reading_seconds
      return false if minimum.zero?

      served_at.nil? || Time.current.to_i - served_at < minimum
    end

    def served_at
      session.dig(:agreement_engine_served, @version.id.to_s)
    end

    def already_signed?
      @version.acceptances.exists?(signer: signer, strength: "signature")
    end

    def stale?
      params.dig(:signature, :content_hash).to_s != @version.content_hash.to_s || current_version != @version
    end

    def current_version
      AgreementEngine::Document.current(@type.key)
    end

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

      session[:agreement_engine_after_consent] = form_url
      redirect_to agreement_engine.consent_path
    end

    def form_url
      agreement_engine.signature_path(@type.key)
    end
    helper_method :form_url

    def after_signing_path
      main_app.root_path
    end

    def set_type_and_version
      @type = AgreementEngine.document_type(params[:document_type])
      @version = @type&.signature? && AgreementEngine::Document.current(@type.key)
      redirect_to main_app.root_path unless @version
    end
  end
end
