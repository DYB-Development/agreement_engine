require "test_helper"

class AgreementFlowTest < ActionDispatch::IntegrationTest
  setup do
    @terms_v1 = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Terms v1 content",
      effective_at: 2.days.ago
    )
    @privacy_v1 = AgreementEngine::Document.create!(
      document_type: "privacy_policy",
      version: "1.0",
      content: "Privacy v1 content",
      effective_at: 2.days.ago
    )
    @user = User.create!(name: "Test User", email: "test@example.com")
  end

  test "user with accepted versions can access protected pages" do
    @user.update!(
      accepted_terms_of_service_version: @terms_v1,
      accepted_privacy_policy_version: @privacy_v1
    )
    sign_in @user

    get root_path
    assert_response :success
  end

  test "user without accepted terms is redirected to agreement page" do
    @user.update!(
      accepted_terms_of_service_version_id: nil,
      accepted_privacy_policy_version: @privacy_v1
    )
    sign_in @user

    get root_path
    assert_redirected_to agreement_engine.agreement_path(:terms_of_service)
  end

  test "accepting agreement redirects back" do
    @user.update!(
      accepted_terms_of_service_version_id: nil,
      accepted_privacy_policy_version: @privacy_v1
    )
    sign_in @user

    patch agreement_engine.agreement_path(:terms_of_service)
    assert_response :see_other

    @user.reload
    assert_equal @terms_v1.id, @user.accepted_terms_of_service_version_id
  end

  test "declining agreement signs user out" do
    @user.update!(
      accepted_terms_of_service_version_id: nil,
      accepted_privacy_policy_version: @privacy_v1
    )
    sign_in @user

    delete agreement_engine.agreement_path(:terms_of_service)
    assert_response :see_other
    assert_match(/please sign in and accept/i, flash[:alert])
  end
end
