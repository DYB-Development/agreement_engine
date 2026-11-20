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

  test "signing without a typed name is refused with a message" do
    give_consent

    patch agreement_engine.signature_path(:statement_of_work), params: {signature: {typed_name: " ", content_hash: @sow.content_hash}}

    assert_select "div", text: "Type your full name to sign."
  end

  test "a signature records the typed name, the consent it relied on and the document hash" do
    give_consent

    patch agreement_engine.signature_path(:statement_of_work), params: {signature: {typed_name: "Pat Lee", content_hash: @sow.content_hash}}

    signature = AgreementEngine::Acceptance.where(document: @sow).last
    assert_equal ["signature", "Pat Lee", @consent.id, @sow.content_hash], [signature.strength, signature.typed_name, signature.consent_id, signature.content_hash]
  end

  test "a signature records the signing statement and button text shown" do
    give_consent

    patch agreement_engine.signature_path(:statement_of_work), params: {signature: {typed_name: "Pat Lee", content_hash: @sow.content_hash}}

    assert_equal "Sign", AgreementEngine::Acceptance.where(document: @sow).last.button_text
  end

  test "a click-accept type has no signing page and keeps its accept page" do
    give_consent

    get agreement_engine.signature_path(:terms_of_service)

    assert_redirected_to "/"
  end

  test "the signing page shows the period the version covers" do
    give_consent
    page = KeystoneUi::Pages::Page.create!(name: "SOW 2", slug: "sow-2", document: KeystoneUi::Pages::Document.blank)
    page.publish
    AgreementEngine::Document.issue!(type: :statement_of_work, page_version: page.live_version, version: "2.0", effective_at: 1.hour.ago, period: {"starts_on" => "2027-01-01", "ends_on" => "2027-06-30"})

    get agreement_engine.signature_path(:statement_of_work)

    assert_select "p", text: "Period: 1 January 2027 to 30 June 2027"
  end

  test "a signature submitted for a version that is no longer current is refused and the current one is shown" do
    give_consent
    page = KeystoneUi::Pages::Page.create!(name: "SOW 3", slug: "sow-3", document: KeystoneUi::Pages::Document.blank)
    page.publish
    AgreementEngine::Document.issue!(type: :statement_of_work, page_version: page.live_version, version: "3.0", effective_at: 1.minute.ago)

    patch agreement_engine.signature_path(:statement_of_work), params: {signature: {typed_name: "Pat Lee", content_hash: @sow.content_hash}}

    assert_equal [0, true], [AgreementEngine::Acceptance.where(strength: "signature").count, response.body.include?("This document changed while you were reading it.")]
  end
end
