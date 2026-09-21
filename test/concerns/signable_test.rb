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

  test "belongs_to accepted_terms_of_service_version" do
    @user.update!(accepted_terms_of_service_version: @terms_v1)
    assert_equal @terms_v1, @user.reload.accepted_terms_of_service_version
  end

  test "belongs_to accepted_privacy_policy_version" do
    privacy_v1 = AgreementEngine::Document.create!(
      document_type: "privacy_policy",
      version: "1.0",
      content: "Privacy v1",
      effective_at: 2.days.ago
    )
    @user.update!(accepted_privacy_policy_version: privacy_v1)
    assert_equal privacy_v1, @user.reload.accepted_privacy_policy_version
  end

  test "needs_acceptance? returns true when user has not accepted current version" do
    agreement = AgreementEngine.config.agreements.find { |a| a.id == :terms_of_service }
    assert @user.needs_acceptance?(agreement)
  end

  test "needs_acceptance? returns false when user has accepted current version" do
    @user.update!(accepted_terms_of_service_version: @terms_v1)
    agreement = AgreementEngine.config.agreements.find { |a| a.id == :terms_of_service }
    assert_not @user.needs_acceptance?(agreement)
  end

  test "accept_version! updates the accepted version" do
    agreement = AgreementEngine.config.agreements.find { |a| a.id == :terms_of_service }
    @user.accept_version!(agreement, @terms_v1)

    assert_equal @terms_v1.id, @user.reload.accepted_terms_of_service_version_id
  end
end
