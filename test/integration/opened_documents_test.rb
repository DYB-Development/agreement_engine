require "test_helper"

class OpenedDocumentsTest < ActionDispatch::IntegrationTest
  setup do
    @terms = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "Terms content", effective_at: 2.days.ago)
  end

  test "host code sees that the session opened the current version on its public page" do
    get agreement_engine.terms_path
    get opened_check_path(:terms_of_service)

    assert_equal "public_page", response.parsed_body["opened_on"]
  end

  test "host code sees no opening when the session never opened the public page" do
    get opened_check_path(:terms_of_service)

    assert_nil response.parsed_body
  end
end
