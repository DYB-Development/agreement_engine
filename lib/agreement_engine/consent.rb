# frozen_string_literal: true

module AgreementEngine
  module Consent
    TYPE = DocumentType.new(key: :electronic_records_consent, title: "Consent to Electronic Records", kind: :standing, strength: :click_accept)
  end
end
