# frozen_string_literal: true

module AgreementEngine
  AcceptanceEvent = Data.define(:acceptance) do
    def document = acceptance.document
    def document_type = document.document_type.to_sym
    def person = acceptance.person
    def account = acceptance.account
    def strength = acceptance.strength.to_sym
    def subject = document.subject

    def first_signature?
      strength == :signature && subject.present? && !document.acceptances.where(strength: "signature").where.not(id: acceptance.id).exists?
    end
  end
end
