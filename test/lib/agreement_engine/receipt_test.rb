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

  def acceptance_with_reading(reading)
    user = User.create!(name: "Pat Lee", email: "pat@example.com")
    document = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "Terms", effective_at: 1.day.ago)
    AgreementEngine::Acceptance.create!(signer: user, document: document, content_hash: "abc123", accepted_at: Time.utc(2026, 11, 20, 15, 30), reading: reading)
  end

  test "the copy lists the minimum reading time and the seconds the server measured" do
    acceptance = acceptance_with_reading({"minimum_seconds" => 30, "measured_seconds" => 42})

    assert_includes AgreementEngine::Receipt.summary_lines(acceptance), "Reading time: 30 seconds required, 42 seconds measured by the server"
  end

  test "the copy lists the browser's report of reaching the end, marked as reported by the browser" do
    acceptance = acceptance_with_reading({"scroll" => {"reported_by" => "browser", "end_reached" => true, "end_in_view_on_load" => false}})

    assert_includes AgreementEngine::Receipt.summary_lines(acceptance), "End of the document: reached, not in view when first shown, as reported by the browser"
  end

  test "the copy says when the browser sent no report of reaching the end" do
    acceptance = acceptance_with_reading({"scroll" => {"reported_by" => nil}})

    assert_includes AgreementEngine::Receipt.summary_lines(acceptance), "End of the document: not reported by the browser"
  end

  test "the copy lists where and when the document was opened, as recorded by the server" do
    acceptance = acceptance_with_reading({"opened_on" => "public_page", "opened_at" => "2026-11-20T15:00:00Z", "version_id" => 1})

    assert_includes AgreementEngine::Receipt.summary_lines(acceptance), "Opened: on the public page, 2026-11-20 15:00:00 UTC, as recorded by the server"
  end
end
