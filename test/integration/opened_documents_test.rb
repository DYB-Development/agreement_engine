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

  test "host code sees when the session first opened the public page" do
    opened = @terms.effective_at.change(usec: 0) + 1.hour
    travel_to(opened) { get agreement_engine.terms_path }
    travel_to(opened + 5.minutes) { get agreement_engine.terms_path }
    get opened_check_path(:terms_of_service)

    assert_equal opened.iso8601, response.parsed_body["opened_at"]
  end

  test "opening an earlier version does not count as opening a newly issued one" do
    get agreement_engine.terms_path
    AgreementEngine::Document.create!(document_type: "terms_of_service", version: "2.0", content: "Terms v2 content", effective_at: Time.current)
    get opened_check_path(:terms_of_service)

    assert_nil response.parsed_body
  end

  test "opening the public page while signed in is recorded" do
    user = User.create!(name: "Test User", email: "test@example.com")
    AgreementEngine::Acceptance.create!(signer: user, document: @terms, accepted_at: 1.day.ago)
    sign_in user
    get agreement_engine.terms_path
    get opened_check_path(:terms_of_service)

    assert_equal "public_page", response.parsed_body["opened_on"]
  end

  test "a person who opens the public page and then signs in still counts as having opened it" do
    get agreement_engine.terms_path
    user = User.create!(name: "Test User", email: "test@example.com")
    AgreementEngine::Acceptance.create!(signer: user, document: @terms, accepted_at: 1.day.ago)
    sign_in user
    get opened_check_path(:terms_of_service)

    assert_equal "public_page", response.parsed_body["opened_on"]
  end
end
