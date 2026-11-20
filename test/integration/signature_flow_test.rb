require "test_helper"

class SignatureFlowTest < ActionDispatch::IntegrationTest
  setup do
    @registered = AgreementEngine.config.document_types
    AgreementEngine.config.document_types = [AgreementEngine::DocumentType.new(key: :statement_of_work, title: "Statement of Work", kind: :standing, strength: :signature)]
    AgreementEngine.config.electronic_consent = true
    @consent_version = AgreementEngine::Consent.seed!
    page = KeystoneUi::Pages::Page.create!(name: "SOW", slug: "sow", document: KeystoneUi::Pages::Document.blank)
    page.publish
    @sow = AgreementEngine::Document.issue!(type: :statement_of_work, page_version: page.live_version, version: "1.0", effective_at: 1.day.ago)
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
    sign_in @user
  end

  teardown do
    AgreementEngine.config.document_types = @registered
    AgreementEngine.config.electronic_consent = false
  end

  def give_consent
    @consent = AgreementEngine::Acceptance.create!(signer: @user, document: @consent_version, accepted_at: 1.hour.ago)
  end

  test "the signing page asks for a typed full name beside wording that says it is a signature" do
    give_consent

    get agreement_engine.signature_path(:statement_of_work)

    assert_select "input[name='signature[typed_name]']"
  end

  test "a person without current consent is sent to the consent page first" do
    get agreement_engine.signature_path(:statement_of_work)

    assert_redirected_to agreement_engine.consent_path
  end

  test "a person who consents on the way to signing is returned to the signing page" do
    get agreement_engine.signature_path(:statement_of_work)

    post agreement_engine.consent_path

    assert_redirected_to agreement_engine.signature_path(:statement_of_work)
  end
end
