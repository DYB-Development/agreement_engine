# frozen_string_literal: true

module AgreementEngine
  class Acceptance < ActiveRecord::Base
    self.table_name = "agreement_engine_acceptances"

    belongs_to :signer, polymorphic: true
    belongs_to :document, class_name: "AgreementEngine::Document"

    def self.record!(signer:, document:)
      create!(signer: signer, document: document, content_hash: document.content_hash, byte_form_version: document.byte_form_version, accepted_at: Time.current)
    end
  end
end
