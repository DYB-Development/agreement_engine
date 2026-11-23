require "test_helper"

class HostLayoutTest < ActionDispatch::IntegrationTest
  setup do
    AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "Terms content", effective_at: 2.days.ago)
    @user = User.create!(name: "Test User", email: "test@example.com")
    sign_in @user
  end

  test "the accept page renders in the host's application layout when the host names none" do
    get agreement_engine.agreement_path(:terms_of_service)

    assert_select "body[data-layout=application]"
  end

  test "the consent page renders in the host's application layout when the host names none" do
    AgreementEngine.config.electronic_consent = true
    AgreementEngine::Consent.seed!

    get agreement_engine.consent_path

    assert_select "body[data-layout=application]"
  ensure
    AgreementEngine.config.electronic_consent = false
  end
end
