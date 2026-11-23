require "test_helper"

class AgreementEngine::SignableTest < ActiveSupport::TestCase
  setup do
    @terms_v1 = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Terms v1",
      effective_at: 2.days.ago
    )
    @user = User.create!(name: "Test User", email: "test@example.com")
  end

  test "needs_acceptance? returns true when user has not accepted current version" do
    assert @user.needs_acceptance?(:terms_of_service)
  end

  test "needs_acceptance? returns false when user has accepted current version" do
    AgreementEngine::Acceptance.create!(signer: @user, document: @terms_v1, accepted_at: Time.current)
    assert_not @user.needs_acceptance?(:terms_of_service)
  end

  test "accept_version! records an acceptance of the version" do
    @user.accept_version!(@terms_v1)

    assert AgreementEngine::Acceptance.exists?(signer: @user, document: @terms_v1)
  end

  test "accept_version! keeps when and where the document was opened" do
    opened = {opened_on: "public_page", opened_at: "2026-11-23T09:00:00Z"}

    assert_equal({"opened_on" => "public_page", "opened_at" => "2026-11-23T09:00:00Z"}, @user.accept_version!(@terms_v1, reading: opened).reading)
  end
end
