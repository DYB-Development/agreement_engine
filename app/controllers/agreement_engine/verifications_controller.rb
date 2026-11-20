# frozen_string_literal: true

module AgreementEngine
  class VerificationsController < ::ApplicationController
    skip_before_action :require_accepted_agreements!, raise: false

    layout "agreement_engine/minimal"

    def show
    end

    def create
      file = params.dig(:verification, :file)
      @matched = file.present? && AgreementEngine::Verification.matches?(file.read, params.dig(:verification, :hash_value))
      render :show
    end
  end
end
