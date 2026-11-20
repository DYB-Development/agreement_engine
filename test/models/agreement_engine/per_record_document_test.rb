require "test_helper"

class AgreementEngine::PerRecordDocumentTest < ActiveSupport::TestCase
  setup do
    @registered = AgreementEngine.config.document_types
    AgreementEngine.config.document_types = [AgreementEngine::DocumentType.new(key: :plan_sign_off, title: "Plan sign-off", kind: :per_record, strength: :signature, template: "plan-sign-off")]
    AgreementEngine.config.values_method = ->(record, _type) { {"client_name" => record.name} }
    document = KeystoneUi::Pages::Document.blank
    document["sections"][0]["rows"][0]["columns"][0]["elements"] << {"id" => "h1", "key" => "heading", "fields" => {"text" => {"value" => "client_name", "fallback" => "Client"}}}
    @template = KeystoneUi::Pages::Page.create!(name: "Plan sign-off", slug: "plan-sign-off", document: document)
    @template.publish
    @record = User.create!(name: "Acme Co", email: "acme@example.com")
  end

  teardown do
    AgreementEngine.config.document_types = @registered
    AgreementEngine.config.values_method = nil
  end

  test "issuing for a record holds the template's live version and the record's values" do
    issued = AgreementEngine.issue_for!(:plan_sign_off, @record)

    assert_equal [@record, @template.live_version, {"client_name" => "Acme Co"}], [issued.subject, issued.page_version, issued.frozen_copy["values"]]
  end
end
