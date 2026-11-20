require "test_helper"
require "digest"

class ReceiptsTest < ActionDispatch::IntegrationTest
  setup do
    document = KeystoneUi::Pages::Document.blank
    document["sections"][0]["rows"][0]["columns"][0]["elements"] << {"id" => "h1", "key" => "heading", "fields" => {"text" => "Our terms"}}
    page = KeystoneUi::Pages::Page.create!(name: "Terms", slug: "terms", document: document)
    page.publish
    @terms = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page.live_version, version: "2.0", effective_at: 1.day.ago)
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
    @acceptance = AgreementEngine::Acceptance.create!(signer: @user, document: @terms, content_hash: @terms.content_hash, accepted_at: Time.current, typed_name: "Pat Lee", engine_version: "0.1.0", pages_version: "0.15.0")
    sign_in @user
  end

  test "the byte-form file a person downloads hashes to the recorded hash" do
    get agreement_engine.byte_form_receipt_path(@acceptance)

    assert_equal @acceptance.content_hash, Digest::SHA256.hexdigest(response.body)
  end
end
