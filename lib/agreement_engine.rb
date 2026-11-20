# frozen_string_literal: true

require_relative "agreement_engine/version"
require "keystone_ui/pages"
require "keystone_ui/pages/document"
require_relative "agreement_engine/configuration"
require_relative "agreement_engine/document_type"
require_relative "agreement_engine/byte_form"
require_relative "agreement_engine/verification"
require_relative "agreement_engine/consent"
require_relative "agreement_engine/seed"
require_relative "agreement_engine/acceptance_event"
require_relative "agreement_engine/period"
require_relative "agreement_engine/receipt"
require_relative "agreement_engine/html_to_page"
require_relative "agreement_engine/upgrade"
require_relative "agreement_engine/integrity"
require_relative "agreement_engine/database_guards"

module AgreementEngine
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def issue_for!(type_key, record, period: nil)
      type = document_type(type_key)
      page_version = KeystoneUi::Pages::Page.find_by!(slug: type.template).live_version
      values = config.values_method.call(record, type).to_h.stringify_keys
      label = (Document.where(document_type: type.key.to_s, subject: record).count + 1).to_s
      Document.issue!(type: type.key, page_version: page_version, version: label, effective_at: Time.current, subject: record, values: values, period: period)
    end

    def current_for(type_key, record)
      Document.where(document_type: type_key.to_s, subject: record).order(:created_at, :id).last
    end

    def signers_for(type_key, record)
      current_for(type_key, record)&.acceptances.to_a.map(&:signer).uniq
    end

    def in_force(on:, person: nil, account_id: nil, record: nil)
      acceptances = Acceptance.includes(:document).order(:accepted_at, :id)
      acceptances = acceptances.where(signer: person) if person
      acceptances = acceptances.where(document: Document.where(subject: record)) if record
      acceptances.select do |acceptance|
        (account_id.nil? || acceptance.account.to_h["id"].to_s == account_id.to_s) && acceptance.in_force_on?(on)
      end
    end

    def document_type(key)
      config.registered_document_types.find { |type| type.key == key.to_sym }
    end
  end
end

require_relative "agreement_engine/engine"
require_relative "agreement_engine/signable"
require_relative "agreement_engine/enforceable"
