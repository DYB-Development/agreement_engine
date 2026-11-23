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
        period_line(acceptance),
        reading_time_line(acceptance.reading.to_h),
        scroll_line(acceptance.reading.to_h["scroll"]),
        opened_line(acceptance.reading.to_h),
        "agreement_engine #{acceptance.engine_version}, keystone_ui-pages #{acceptance.pages_version}"
      ].compact
    end

    def reading_time_line(reading)
      return unless reading["minimum_seconds"]

      "Reading time: #{reading["minimum_seconds"]} seconds required, #{reading["measured_seconds"]} seconds measured by the server"
    end

    def scroll_line(scroll)
      return unless scroll
      return "End of the document: not reported by the browser" unless scroll["reported_by"]

      reached = scroll["end_reached"] ? "reached" : "not reached"
      on_load = scroll["end_in_view_on_load"] ? "in view when first shown" : "not in view when first shown"
      "End of the document: #{reached}, #{on_load}, as reported by the browser"
    end

    def opened_line(reading)
      return unless reading["opened_on"]

      at = Time.iso8601(reading["opened_at"]).utc.strftime("%Y-%m-%d %H:%M:%S UTC")
      "Opened: on the #{reading["opened_on"].tr("_", " ")}, #{at}, as recorded by the server"
    end

    def period_line(acceptance)
      described = Period.describe(acceptance.document.frozen_copy.to_h["period"])
      return unless described

      dates = [acceptance.period_starts_on, acceptance.period_ends_on].compact
      dates.size == 2 && acceptance.document.frozen_copy["period"]["duration"] ? "Period: #{described}, #{Period.day(dates[0])} to #{Period.day(dates[1])}" : "Period: #{described}"
    end

    def byte_form(acceptance)
      copy = acceptance.document.frozen_copy
      ByteForm.encode(slug: copy["slug"], number: copy["number"], document: copy["document"], values: copy["values"] || {}, period: copy["period"])
    end
  end
end
