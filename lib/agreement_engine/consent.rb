# frozen_string_literal: true

require "securerandom"

module AgreementEngine
  module Consent
    TYPE = DocumentType.new(key: :electronic_records_consent, title: "Consent to Electronic Records", kind: :standing, strength: :click_accept)

    STARTING_TEXT = [
      [:heading, "Consent to Electronic Records"],
      [:paragraph, "We would like to give you agreements, notices and other records electronically, and to have you sign them electronically. Please read this before you agree."],
      [:heading, "Paper copies"],
      [:paragraph, "You may ask for a paper copy of any record we give you electronically by contacting us. We will tell you of any fee before we send it."],
      [:heading, "Withdrawing your consent"],
      [:paragraph, "You may withdraw this consent at any time from your account. Withdrawing does not change records you have already signed. After you withdraw, we will tell you how we will give you records from then on."],
      [:heading, "What you need to open and keep records"],
      [:paragraph, "You need a device with a current web browser, an internet connection, a program that opens PDF files and an email address. You can keep a record by downloading or printing it. If these needs change, we will tell you and ask for your consent again."]
    ].freeze

    module_function

    def seed!
      return if Document.where(document_type: TYPE.key.to_s).exists?

      page = KeystoneUi::Pages::Page.create!(name: TYPE.title, slug: "electronic-records-consent", document: starting_document)
      page.publish
      Document.issue!(type: TYPE.key, page_version: page.live_version, version: "1.0", effective_at: Time.current)
    end

    def starting_document
      document = KeystoneUi::Pages::Document.blank
      document["sections"][0]["rows"][0]["columns"][0]["elements"] = STARTING_TEXT.map do |key, text|
        {"id" => SecureRandom.uuid, "key" => key.to_s, "fields" => {"text" => text}}
      end
      document
    end
  end
end
