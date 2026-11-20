# frozen_string_literal: true

require "securerandom"

module AgreementEngine
  module Seed
    module_function

    def run
      AgreementEngine.config.registered_document_types.select(&:standing?).filter_map do |type|
        next Consent.seed! if type.key == Consent::TYPE.key

        issue_starting_version(type, placeholder_text(type))
      end
    end

    def issue_starting_version(type, text)
      return if Document.where(document_type: type.key.to_s, subject_id: nil).exists?

      page = KeystoneUi::Pages::Page.create!(name: type.title, slug: "agreement-#{type.key.to_s.dasherize}", place: AgreementEngine.config.pages_place, document: document_of(text))
      page.publish
      Document.issue!(type: type.key, page_version: page.live_version, version: "1.0", effective_at: Time.current)
    end

    def placeholder_text(type)
      [[:heading, type.title], [:paragraph, "This is a placeholder. Replace it with your #{type.title.downcase} in the page builder, then issue a new version."]]
    end

    def document_of(text)
      document = KeystoneUi::Pages::Document.blank
      document["sections"][0]["rows"][0]["columns"][0]["elements"] = text.map do |key, value|
        {"id" => SecureRandom.uuid, "key" => key.to_s, "fields" => {"text" => value}}
      end
      document
    end
  end
end
