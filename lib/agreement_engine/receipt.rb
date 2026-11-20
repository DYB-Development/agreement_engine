# frozen_string_literal: true

module AgreementEngine
  module Receipt
    module_function

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
