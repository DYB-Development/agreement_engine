require "test_helper"

class RecordDocumentFlowTest < ActionDispatch::IntegrationTest
  setup do
    @registered = AgreementEngine.config.document_types
    AgreementEngine.config.document_types = [
      AgreementEngine::DocumentType.new(key: :plan_sign_off, title: "Plan sign-off", kind: :per_record, strength: :signature, template: "plan-sign-off"),
      AgreementEngine::DocumentType.new(key: :quote, title: "Quote", kind: :per_record, strength: :click_accept, template: "plan-sign-off")
    ]
    AgreementEngine.config.values_method = ->(record, _type) { {"client_name" => record.name} }
    AgreementEngine.config.may_sign_method = ->(_controller, person, document) { document.subject == person }
    AgreementEngine.config.electronic_consent = true
    consent_version = AgreementEngine::Consent.seed!
    document = KeystoneUi::Pages::Document.blank
    document["sections"][0]["rows"][0]["columns"][0]["elements"] << {"id" => "h1", "key" => "heading", "fields" => {"text" => {"value" => "client_name", "fallback" => "Client"}}}
    KeystoneUi::Pages::Page.create!(name: "Plan sign-off", slug: "plan-sign-off", document: document).publish
    @client = User.create!(name: "Acme Co", email: "acme@example.com")
    AgreementEngine::Acceptance.create!(signer: @client, document: consent_version, accepted_at: 1.hour.ago)
    @plan_document = AgreementEngine.issue_for!(:plan_sign_off, @client)
    sign_in @client
  end

  teardown do
    AgreementEngine.config.document_types = @registered
    AgreementEngine.config.values_method = nil
    AgreementEngine.config.may_sign_method = nil
    AgreementEngine.config.electronic_consent = false
  end

  test "the signing page for a record's document shows the record's values" do
    get agreement_engine.record_document_path(@plan_document)

    assert_select "h2, h1, h3, div", text: /Acme Co/
  end

  test "a person the host refuses cannot see a record's document" do
    sign_in User.create!(name: "Someone Else", email: "else@example.com")

    get agreement_engine.record_document_path(@plan_document)

    assert_response :not_found
  end

  test "a person the host refuses cannot sign a record's document" do
    sign_in User.create!(name: "Someone Else", email: "else@example.com")

    patch agreement_engine.record_document_path(@plan_document), params: {signature: {typed_name: "Someone Else"}}

    assert_equal 0, @plan_document.acceptances.count
  end

  test "after signing, the person is sent to the page on the host's site the link named" do
    patch agreement_engine.record_document_path(@plan_document, return_to: "/plans/abc"), params: {signature: {typed_name: "Acme Co"}}

    assert_redirected_to "/plans/abc"
  end

  test "a return address on another site is ignored" do
    patch agreement_engine.record_document_path(@plan_document, return_to: "https://evil.example/steal"), params: {signature: {typed_name: "Acme Co"}}

    assert_redirected_to "/"
  end

  test "a return address the host's check refuses is ignored" do
    AgreementEngine.config.return_check_method = ->(path) { path.start_with?("/plans/") }

    patch agreement_engine.record_document_path(@plan_document, return_to: "/admin/secret"), params: {signature: {typed_name: "Acme Co"}}

    assert_redirected_to "/"
  ensure
    AgreementEngine.config.return_check_method = nil
  end

  test "a click-accept record document is accepted without a typed name" do
    quote = AgreementEngine.issue_for!(:quote, @client)

    patch agreement_engine.record_document_path(quote)

    assert_equal "click_accept", quote.acceptances.last&.strength
  end

  test "host code asks who has signed a record's current document" do
    patch agreement_engine.record_document_path(@plan_document), params: {signature: {typed_name: "Acme Co"}}

    assert_equal [@client], AgreementEngine.signers_for(:plan_sign_off, @client)
  end

  test "a record's current document has no signers once a revised one is issued" do
    patch agreement_engine.record_document_path(@plan_document), params: {signature: {typed_name: "Acme Co"}}
    AgreementEngine.issue_for!(:plan_sign_off, @client)

    assert_empty AgreementEngine.signers_for(:plan_sign_off, @client)
  end

  test "an unsigned record document never redirects a signed-in person to accept it" do
    AgreementEngine::Acceptance.create!(signer: @client, document: AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "Terms", effective_at: 1.day.ago), accepted_at: Time.current)
    AgreementEngine::Acceptance.create!(signer: @client, document: AgreementEngine::Document.create!(document_type: "privacy_policy", version: "1.0", content: "Privacy", effective_at: 1.day.ago), accepted_at: Time.current)

    get "/"

    assert_response :success
  end
end
