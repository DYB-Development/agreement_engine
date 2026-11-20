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
end
