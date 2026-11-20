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
end
