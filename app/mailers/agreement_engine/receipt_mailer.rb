# frozen_string_literal: true

module AgreementEngine
  class ReceiptMailer < ActionMailer::Base
    rescue_from StandardError do |error|
      Rails.error.report(error, handled: true, source: "agreement_engine")
    end

    def copy(acceptance)
      @acceptance = acceptance
      @type = AgreementEngine.document_type(acceptance.document.document_type)
      name = "#{acceptance.document.document_type}-#{acceptance.document.version}"
      attachments["#{name}.pdf"] = {mime_type: "application/pdf", content: AgreementEngine::Receipt.pdf(acceptance)}
      attachments["#{name}.json"] = {mime_type: "application/json", content: AgreementEngine::Receipt.byte_form(acceptance)}
      mail(to: acceptance.person["email"], from: AgreementEngine.config.mailer_from || "no-reply@example.com", subject: t(".subject", document: @type&.title || acceptance.document.document_type.titleize))
    end
  end
end
