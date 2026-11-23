# frozen_string_literal: true

module AgreementEngine
  module Enforceable
    extend ActiveSupport::Concern

    included do
      before_action :require_accepted_agreements!,
        if: -> { request.get? && AgreementEngine.config.signed_in?(self) && !AgreementEngine.config.auth_controller?(self) }
    end

    def require_accepted_agreements!
      person = AgreementEngine.config.current_user(self)
      type = AgreementEngine.config.registered_document_types.find { |candidate| candidate.standing? && candidate.prompts && !person.accepted_current?(candidate.key) }
      return unless type

      store_location_for(:user, request.fullpath) unless request.fullpath.start_with?("/agreements/")
      redirect_to agreement_engine.agreement_path(type)
    end

    def agreement_engine_opened(document_type)
      version = AgreementEngine::Document.current(document_type)
      opened_at = version && session.dig(:agreement_engine_opened, version.id.to_s)
      return unless opened_at

      {opened_on: "public_page", opened_at: Time.zone.at(opened_at).iso8601}
    end
  end
end
