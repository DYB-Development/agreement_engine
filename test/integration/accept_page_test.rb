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

  test "the accept page's last updated date is a keystone_ui caption" do
    get agreement_engine.agreement_path(:terms_of_service)

    assert_select ".ks-caption", text: "Last updated #{I18n.l(@terms.effective_at.to_date, format: :long)}"
  end

  test "the accept page's statement is a keystone_ui paragraph" do
    get agreement_engine.agreement_path(:terms_of_service)

    assert_select "p.ks-paragraph", text: "Before you can proceed, you must read and accept the new Terms Of Service."
  end

  test "the accept page's decline button is a keystone_ui button" do
    get agreement_engine.agreement_path(:terms_of_service)

    assert_select "button.ks-button-secondary", text: "I Decline"
  end
end
