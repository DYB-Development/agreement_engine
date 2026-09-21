# frozen_string_literal: true

module AgreementEngine
  module Enforceable
    extend ActiveSupport::Concern

    included do
      before_action :require_accepted_agreements!,
        if: -> { request.get? && AgreementEngine.config.signed_in?(self) && !AgreementEngine.config.auth_controller?(self) }
    end

    def require_accepted_agreements!
      AgreementEngine.config.agreements.select(&:prompt_when_updated).each do |agreement|
        if agreement.not_accepted_by?(AgreementEngine.config.current_user(self))
          store_location_for(:user, request.fullpath) unless request.fullpath.start_with?("/agreements/")
          redirect_to agreement_engine.agreement_path(agreement)
          break
        end
      end
    end
  end
end
