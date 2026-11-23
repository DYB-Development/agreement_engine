# frozen_string_literal: true

module AgreementEngine
  class AgreementsController < ::ApplicationController
    skip_before_action :require_accepted_agreements!, raise: false
    before_action :agreement_engine_authenticate_user!
    before_action :set_agreement
    before_action :set_version

    layout -> { AgreementEngine.config.layout }

    def show
      record_served
    end

    def update
      return refuse(t(".too_soon", agreement: @agreement.title, seconds: @agreement.minimum_reading_seconds)) if @version && too_soon?

      if @version
        AgreementEngine::Acceptance.record!(signer: agreement_engine_current_user, document: @version, request: request, statement: t("agreement_engine.agreements.show.description", agreement: @agreement.title), button_text: t("agreement_engine.agreements.show.accept"), evidence: AgreementEngine.config.evidence(self, agreement_engine_current_user), reading: reading_evidence)
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

    def refuse(reason)
      @error = reason
      render :show, status: :unprocessable_entity
    end

    def record_served
      return unless @version

      served = session[:agreement_engine_served] ||= {}
      served[@version.id.to_s] ||= Time.current.to_i
    end

    def too_soon?
      minimum = @agreement.minimum_reading_seconds
      return false if minimum.zero?

      served_at.nil? || Time.current.to_i - served_at < minimum
    end

    def reading_evidence
      evidence = {}
      minimum = @agreement.minimum_reading_seconds
      evidence.merge!(minimum_seconds: minimum, measured_seconds: Time.current.to_i - served_at) unless minimum.zero?
      evidence.merge!(opened_on: "accept_page", opened_at: Time.zone.at(served_at).iso8601) if @agreement.requires_opening? && served_at
      evidence.presence
    end

    def served_at
      session.dig(:agreement_engine_served, @version.id.to_s)
    end

    def after_accepted_path
      stored_location_for(:user) || main_app.root_path
    end
  end
end
