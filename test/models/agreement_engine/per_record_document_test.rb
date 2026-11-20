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

  test "changing the record afterwards changes neither the issued document's values nor its hash" do
    issued = AgreementEngine.issue_for!(:plan_sign_off, @record)
    hash_at_issue = issued.content_hash

    @record.update!(name: "Acme Renamed")

    assert_equal [{"client_name" => "Acme Co"}, hash_at_issue], issued.reload.then { |document| [document.frozen_copy["values"], document.content_hash] }
  end

  test "issuing a revised document for the same record keeps the earlier one and its acceptances" do
    first = AgreementEngine.issue_for!(:plan_sign_off, @record)
    acceptance = AgreementEngine::Acceptance.create!(signer: @record, document: first, accepted_at: Time.current)

    AgreementEngine.issue_for!(:plan_sign_off, @record)

    assert_equal [first, acceptance], [AgreementEngine::Document.find(first.id), first.acceptances.first]
  end

  test "host code finds a record's current document, the latest issued for it" do
    AgreementEngine.issue_for!(:plan_sign_off, @record)
    revised = AgreementEngine.issue_for!(:plan_sign_off, @record)

    assert_equal revised, AgreementEngine.current_for(:plan_sign_off, @record)
  end

  test "a record's document is never taken as the current version of a standing document" do
    AgreementEngine.issue_for!(:plan_sign_off, @record)

    assert_nil AgreementEngine::Document.current(:plan_sign_off)
  end
end
