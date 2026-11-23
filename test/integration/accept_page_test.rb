require "test_helper"

class AcceptPageTest < ActionDispatch::IntegrationTest
  setup do
    @terms = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "Terms content", effective_at: 2.days.ago)
    @user = User.create!(name: "Test User", email: "test@example.com")
    sign_in @user
  end

  test "the accept page's heading is a keystone_ui heading" do
    get agreement_engine.agreement_path(:terms_of_service)

    assert_select ".ks-heading-lg", text: "Terms Of Service Changed"
  end
end
