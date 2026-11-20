# frozen_string_literal: true

module AgreementEngine
  AcceptanceEvent = Data.define(:acceptance, :first_signature) do
    def self.for(acceptance)
      new(acceptance: acceptance, first_signature: first_signature?(acceptance))
    end

    def self.first_signature?(acceptance)
      acceptance.strength == "signature" && acceptance.document.subject_id.present? &&
        !acceptance.document.acceptances.where(strength: "signature").where.not(id: acceptance.id).exists?
    end

    def document = acceptance.document
    def document_type = document.document_type.to_sym
    def person = acceptance.person
    def account = acceptance.account
    def strength = acceptance.strength.to_sym
    def subject = document.subject
    def first_signature? = first_signature
  end
end
