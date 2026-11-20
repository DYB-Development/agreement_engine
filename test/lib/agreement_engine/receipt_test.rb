require "test_helper"

class AgreementEngine::ReceiptTest < ActiveSupport::TestCase
  test "the copy's summary names the hash, the time, the typed name and the gem versions" do
    user = User.create!(name: "Pat Lee", email: "pat@example.com")
    document = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "Terms", effective_at: 1.day.ago)
    acceptance = AgreementEngine::Acceptance.create!(signer: user, document: document, content_hash: "abc123", accepted_at: Time.utc(2026, 11, 20, 15, 30), typed_name: "Pat Lee", engine_version: "0.2.0", pages_version: "0.15.0")

    assert_equal [
      "SHA-256: abc123",
      "Accepted: 2026-11-20 15:30:00 UTC",
      "Typed name: Pat Lee",
      "agreement_engine 0.2.0, keystone_ui-pages 0.15.0"
    ], AgreementEngine::Receipt.summary_lines(acceptance)
  end
end
