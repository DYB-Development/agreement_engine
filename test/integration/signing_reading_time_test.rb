require "test_helper"

class SigningReadingTimeTest < ActionDispatch::IntegrationTest
  setup do
    @registered = AgreementEngine.config.document_types
    AgreementEngine.config.document_types = [AgreementEngine::DocumentType.new(key: :statement_of_work, title: "Statement of Work", kind: :standing, strength: :signature, reading: {seconds: 30})]
    AgreementEngine.config.electronic_consent = true
    consent_version = AgreementEngine::Consent.seed!
    page = KeystoneUi::Pages::Page.create!(name: "SOW", slug: "sow", document: KeystoneUi::Pages::Document.blank)
    page.publish
    @sow = AgreementEngine::Document.issue!(type: :statement_of_work, page_version: page.live_version, version: "1.0", effective_at: 1.day.ago)
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
    AgreementEngine::Acceptance.create!(signer: @user, document: consent_version, accepted_at: 1.hour.ago)
    sign_in @user
  end

  teardown do
    AgreementEngine.config.document_types = @registered
    AgreementEngine.config.electronic_consent = false
  end

  def sign
    patch agreement_engine.signature_path(:statement_of_work), params: {signature: {typed_name: "Pat Lee", content_hash: @sow.content_hash}}
  end

  test "a signature sent sooner than the minimum reading time is refused with the reason" do
    get agreement_engine.signature_path(:statement_of_work)
    sign

    assert_includes response.body, "Read the Statement of Work for at least 30 seconds before signing."
  end

  test "a signature keeps the minimum time that applied and the seconds the server measured" do
    get agreement_engine.signature_path(:statement_of_work)
    travel 31.seconds
    sign

    assert_equal({"minimum_seconds" => 30, "measured_seconds" => 31}, AgreementEngine::Acceptance.find_by(signer: @user, document: @sow).reading)
  end

  test "a signature of a type requiring scrolling keeps the browser's scroll report" do
    AgreementEngine.config.document_types = [AgreementEngine::DocumentType.new(key: :statement_of_work, title: "Statement of Work", kind: :standing, strength: :signature, reading: {scroll: true})]
    get agreement_engine.signature_path(:statement_of_work)
    patch agreement_engine.signature_path(:statement_of_work), params: {signature: {typed_name: "Pat Lee", content_hash: @sow.content_hash}, reading: {end_reached: "true", end_in_view_on_load: "true"}}

    assert_equal({"reported_by" => "browser", "end_reached" => true, "end_in_view_on_load" => true}, AgreementEngine::Acceptance.find_by(signer: @user, document: @sow).reading["scroll"])
  end
end
