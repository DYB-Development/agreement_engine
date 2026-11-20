# frozen_string_literal: true

module AgreementEngine
  class Acceptance < ActiveRecord::Base
    self.table_name = "agreement_engine_acceptances"

    belongs_to :signer, polymorphic: true

    before_create :set_period
    after_create_commit :tell_host
    after_create_commit :email_copy

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

    def set_period
      period = document.frozen_copy.to_h["period"]
      return if period.blank?

      if period["duration"]
        return unless accepted_at

        self.period_starts_on = accepted_at.to_date
        self.period_ends_on = period_starts_on + ActiveSupport::Duration.parse(period["duration"])
      else
        self.period_starts_on = period["starts_on"]&.to_date
        self.period_ends_on = period["ends_on"]&.to_date
      end
    end

    def email_copy
      return unless AgreementEngine.config.copy_email_types.map(&:to_s).include?(document.document_type)
      return if person.to_h["email"].blank?

      AgreementEngine::ReceiptMailer.copy(self).deliver_later
    rescue => error
      Rails.error.report(error, handled: true, source: "agreement_engine")
    end

    def tell_host
      handler = AgreementEngine.config.acceptance_handler
      handler&.call(AcceptanceEvent.for(self))
    rescue => error
      Rails.error.report(error, handled: true, source: "agreement_engine")
    end

    def self.person_snapshot(signer)
      {"id" => signer.id, "name" => signer.try(:name), "email" => signer.try(:email)}
    end
  end
end
