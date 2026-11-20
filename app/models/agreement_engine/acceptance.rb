# frozen_string_literal: true

module AgreementEngine
  class Acceptance < ActiveRecord::Base
    self.table_name = "agreement_engine_acceptances"

    belongs_to :signer, polymorphic: true

    def readonly?
      persisted?
    end

    belongs_to :document, class_name: "AgreementEngine::Document"
    has_one :consent_withdrawal, class_name: "AgreementEngine::ConsentWithdrawal"
    belongs_to :consent, class_name: "AgreementEngine::Acceptance", optional: true

    def self.record!(signer:, document:, request:, statement:, button_text:, evidence: {}, signature: {})
      create!(
        signer: signer,
        person: person_snapshot(signer).merge(evidence[:person].to_h.stringify_keys),
        account: evidence[:account],
        sign_in: evidence[:sign_in],
        document: document,
        content_hash: document.content_hash,
        byte_form_version: document.byte_form_version,
        accepted_at: Time.current,
        engine_version: AgreementEngine::VERSION,
        pages_version: KeystoneUi::Pages::VERSION,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        statement: statement,
        button_text: button_text,
        **signature
      )
    end

    def self.person_snapshot(signer)
      {"id" => signer.id, "name" => signer.try(:name), "email" => signer.try(:email)}
    end
  end
end
