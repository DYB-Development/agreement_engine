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
end
