# frozen_string_literal: true

require "keystone_ui/pages/pdf_drawing"

module AgreementEngine
  module Receipt
    module_function

    def pdf(acceptance)
      copy = acceptance.document.frozen_copy
      surface = KeystoneUi::Pages::PdfSurface.new(KeystoneUi::Pages::PdfLook.host)
      KeystoneUi::Pages::PdfDrawing.draw(copy["document"], surface, values: copy["values"] || {})
      surface.space(KeystoneUi::Pages::PdfDrawing::SPACING, 8)
      summary_lines(acceptance).each do |line|
        surface.text(line, size: KeystoneUi::Pages::PdfElements::NOTE_SIZE, font: "--ks-font-body", color: "--ks-color-text-muted", leading: "--leading-relaxed")
      end
      surface.render
    end

    def summary_lines(acceptance)
      [
        "SHA-256: #{acceptance.content_hash}",
        "Accepted: #{acceptance.accepted_at.utc.strftime("%Y-%m-%d %H:%M:%S UTC")}",
        ("Typed name: #{acceptance.typed_name}" if acceptance.typed_name.present?),
        "agreement_engine #{acceptance.engine_version}, keystone_ui-pages #{acceptance.pages_version}"
      ].compact
    end

    def byte_form(acceptance)
      copy = acceptance.document.frozen_copy
      ByteForm.encode(slug: copy["slug"], number: copy["number"], document: copy["document"], values: copy["values"] || {})
    end
  end
end
