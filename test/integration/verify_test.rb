require "test_helper"
require "digest"

class VerifyTest < ActionDispatch::IntegrationTest
  def upload(content)
    Rack::Test::UploadedFile.new(StringIO.new(content), "application/json", original_filename: "copy.json")
  end

  test "anyone, signed in or not, sees that a byte-form file matches its hash" do
    bytes = %({"document":{},"number":1,"period":null,"slug":"terms","values":{}})

    post agreement_engine.verification_path, params: {verification: {file: upload(bytes), hash_value: Digest::SHA256.hexdigest(bytes)}}

    assert_select "p", text: "The file matches this hash."
  end

  test "the verify page shows no personal details of a signer whose hash it checks" do
    user = User.create!(name: "Pat Lee", email: "pat@example.com")
    document = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "Terms", effective_at: 1.day.ago)
    bytes = %({"document":{},"number":1,"period":null,"slug":"terms","values":{}})
    AgreementEngine::Acceptance.create!(signer: user, document: document, content_hash: Digest::SHA256.hexdigest(bytes), accepted_at: Time.current, person: {"name" => "Pat Lee", "email" => "pat@example.com"})

    post agreement_engine.verification_path, params: {verification: {file: upload(bytes), hash_value: Digest::SHA256.hexdigest(bytes)}}

    assert_not_includes response.body, "pat@example.com"
  end
end
