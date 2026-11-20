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
  end
end
