# frozen_string_literal: true

module AgreementEngine
  module Upgrade
    Report = Data.define(:left_out)

    module_function

    def run
      left_out = []
      legacy_versions.group_by(&:document_type).each do |document_type, versions|
        page = page_for(document_type)
        versions.each do |version|
          missed = carry_over_version(page, version)
          left_out << [version.document_type, version.version, missed] if missed.any?
        end
      end
      Report.new(left_out: left_out)
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
      converted = HtmlToPage.convert(version.content.body.to_html)
      page.edit(converted.document)
      page.publish
      converted.left_out
    end
  end
end
