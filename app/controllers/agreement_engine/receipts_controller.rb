# frozen_string_literal: true

module AgreementEngine
  class ReceiptsController < ::ApplicationController
    skip_before_action :require_accepted_agreements!, raise: false
    before_action :require_signed_in
    before_action :set_acceptance

    def show
      send_data AgreementEngine::Receipt.pdf(@acceptance), filename: "#{file_name}.pdf", type: "application/pdf", disposition: "attachment"
    end

    def byte_form
      send_data AgreementEngine::Receipt.byte_form(@acceptance), filename: "#{file_name}.json", type: "application/json"
    end

    private

    def require_signed_in
      redirect_to main_app.root_path unless AgreementEngine.config.signed_in?(self)
    end

    def set_acceptance
      @acceptance = AgreementEngine.config.current_user(self).agreement_engine_acceptances.find(params[:id])
    end

    def file_name
      "#{@acceptance.document.document_type}-#{@acceptance.document.version}"
    end
  end
end
