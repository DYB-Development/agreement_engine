require "test_helper"

class ConsentFlowTest < ActionDispatch::IntegrationTest
  setup do
    AgreementEngine.config.electronic_consent = true
    @consent = AgreementEngine::Consent.seed!
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
    sign_in @user
  end

  teardown do
    AgreementEngine.config.electronic_consent = false
  end

  test "a person gives consent and it is recorded with the evidence of any acceptance" do
    post agreement_engine.consent_path, env: {"REMOTE_ADDR" => "203.0.113.9"}

    assert_equal [@consent.id, "203.0.113.9"], AgreementEngine::Acceptance.last.then { |acceptance| [acceptance.document_id, acceptance.ip_address] }
  end

  test "withdrawing consent records the time it was withdrawn against the consent" do
    post agreement_engine.consent_path
    consent = AgreementEngine::Acceptance.last

    travel_to Time.utc(2026, 12, 1, 9, 0) do
      delete agreement_engine.consent_path
    end

    assert_equal [consent.id, Time.utc(2026, 12, 1, 9, 0)], AgreementEngine::ConsentWithdrawal.last.then { |withdrawal| [withdrawal.acceptance_id, withdrawal.withdrawn_at] }
  end

  test "the consent page's consent button is a keystone_ui button" do
    get agreement_engine.consent_path

    assert_select "button.ks-button", text: "I Consent"
  end

  test "the consent page's statement is a keystone_ui paragraph" do
    get agreement_engine.consent_path

    assert_select "article + div p.ks-paragraph", text: "I have read this disclosure, I can open and keep records as it describes, and I agree to receive and sign records electronically."
  end

  test "a person who holds consent sees a keystone_ui withdraw button" do
    post agreement_engine.consent_path
    get agreement_engine.consent_path

    assert_select "button.ks-button-secondary", text: "Withdraw"
  end

  test "a person who holds consent is told so in a keystone_ui paragraph" do
    post agreement_engine.consent_path
    get agreement_engine.consent_path

    assert_select "article + div p.ks-paragraph", text: "You have consented to electronic records. You can withdraw that consent here."
  end
end
