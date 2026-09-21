# frozen_string_literal: true

module AgreementEngine
  module Signable
    extend ActiveSupport::Concern

    included do
      AgreementEngine.config.agreements.each do |agreement|
        belongs_to :"accepted_#{agreement.document_type}_version",
          class_name: "AgreementEngine::Document",
          optional: true
      end
    end

    def needs_acceptance?(agreement)
      agreement.not_accepted_by?(self)
    end

    def accept_version!(agreement, version)
      update!(agreement.version_column => version.id)
    end
  end
end
