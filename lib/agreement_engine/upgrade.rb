# frozen_string_literal: true

module AgreementEngine
  module Upgrade
    Report = Data.define(:left_out)

    module_function

    def run(signer_class: nil, time_column: nil)
      left_out = []
      legacy_versions.group_by(&:document_type).each do |document_type, versions|
        page = page_for(document_type)
        versions.each do |version|
          missed = carry_over_version(page, version)
          left_out << [version.document_type, version.version, missed] if missed.any?
        end
      end
      carry_over_acceptances(signer_class, time_column) if signer_class
      Report.new(left_out: left_out)
    end

    def carry_over_acceptances(signer_class, time_column)
      AgreementEngine.config.registered_document_types.select(&:standing?).each do |type|
        column = "accepted_#{type.key}_version_id"
        next unless signer_class.column_names.include?(column)

        signer_class.where.not(column => nil).find_each do |signer|
          document = Document.find_by(id: signer.public_send(column))
          next unless document
          next if Acceptance.exists?(signer: signer, document: document, carried_over: true)

          reported_time = time_column && signer.public_send(time_column)
          evidence = evidence_at_upgrade(signer)
          Acceptance.create!(
            signer: signer,
            document: document,
            content_hash: document.content_hash,
            byte_form_version: document.byte_form_version,
            carried_over: true,
            accepted_at: reported_time,
            time_reported_by_host: reported_time.present?,
            person: Acceptance.person_snapshot(signer).merge(evidence[:person].to_h.stringify_keys),
            account: evidence[:account],
            snapshot_taken_at: Time.current
          )
        end
      end
    end

    def legacy_versions
      Document.where(content_hash: nil, subject_id: nil).where.not(effective_at: nil).order(:effective_at, :id).to_a
    end

    def evidence_at_upgrade(signer)
      AgreementEngine.config.evidence(nil, signer)
    rescue => error
      Rails.error.report(error, handled: true, source: "agreement_engine")
      {}
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
      version.issue_in_place!(page.live_version)
      converted.left_out
    end
  end
end
