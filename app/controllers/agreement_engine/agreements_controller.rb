# frozen_string_literal: true

module AgreementEngine
  class AgreementsController < ::ApplicationController
    skip_before_action :require_accepted_agreements!, raise: false
    before_action :agreement_engine_authenticate_user!
    before_action :set_agreement
    before_action :set_version

    layout "agreement_engine/minimal"

    def show
    end

    def update
      if @version
        AgreementEngine::Acceptance.record!(signer: agreement_engine_current_user, document: @version, request: request, statement: t("agreement_engine.agreements.show.description", agreement: @agreement.title), button_text: t("agreement_engine.agreements.show.accept"), evidence: AgreementEngine.config.evidence(self, agreement_engine_current_user))
      end
      redirect_to after_accepted_path, status: :see_other
    end

    def destroy
      AgreementEngine.config.sign_out(self)
      redirect_to main_app.root_path, status: :see_other, alert: t(".declined", agreement: @agreement.title)
    end

    private

    def agreement_engine_current_user
      AgreementEngine.config.current_user(self)
    end

    def agreement_engine_authenticate_user!
      unless AgreementEngine.config.signed_in?(self)
        redirect_to main_app.root_path
      end
    end

    def set_agreement
      @agreement = AgreementEngine.document_type(params[:id])

      if @agreement.nil? || @agreement.per_record?
        redirect_to main_app.root_path
      elsif agreement_engine_current_user.accepted_current?(@agreement.key)
        redirect_to after_accepted_path
      end
    end

    def set_version
      @version = @agreement && AgreementEngine::Document.current(@agreement.key)
    end

    def after_accepted_path
      stored_location_for(:user) || main_app.root_path
    end
  end
end
