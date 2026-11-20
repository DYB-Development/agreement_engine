# frozen_string_literal: true

module AgreementEngine
  module Signable
    extend ActiveSupport::Concern

    included do
      has_many :agreement_engine_acceptances, -> { order(:accepted_at, :id) }, as: :signer, class_name: "AgreementEngine::Acceptance"
    end

    def accepted_versions(document_type)
      agreement_engine_acceptances.includes(:document).map(&:document).select { |document| document.document_type == document_type.to_s }
    end

    def accepted_current?(document_type)
      current = AgreementEngine::Document.current(document_type)
      current.nil? || agreement_engine_acceptances.exists?(document: current)
    end

    def holds_consent?
      held_consent.present?
    end

    def held_consent
      current = AgreementEngine::Document.current(AgreementEngine::Consent::TYPE.key)
      return unless current

      agreement_engine_acceptances.where(document: current).where.missing(:consent_withdrawal).last
    end

    def needs_acceptance?(document_type)
      !accepted_current?(document_type)
    end

    def accept_version!(version)
      AgreementEngine::Acceptance.create!(signer: self, person: AgreementEngine::Acceptance.person_snapshot(self), document: version, content_hash: version.content_hash, byte_form_version: version.byte_form_version, accepted_at: Time.current)
    end
  end
end
