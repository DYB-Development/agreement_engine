# frozen_string_literal: true

module AgreementEngine
  module Upgrade
    module_function

    def run
      legacy_versions.group_by(&:document_type).each do |document_type, versions|
        page = page_for(document_type)
        versions.each { |version| carry_over_version(page, version) }
      end
    end

    def legacy_versions
      Document.where(content_hash: nil, subject_id: nil).where.not(effective_at: nil).order(:effective_at, :id).to_a
    end

    def page_for(document_type)
      KeystoneUi::Pages::Page.find_or_create_by!(slug: "agreement-#{document_type.to_s.dasherize}") do |page|
        page.name = document_type.to_s.titleize
      end
    end

    def carry_over_version(page, version)
      page.edit(KeystoneUi::Pages::Document.blank)
      page.publish
    end
  end
end
