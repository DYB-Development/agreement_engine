require "test_helper"
require "digest"
require "json"

class AgreementEngine::ByteFormExamplesTest < ActiveSupport::TestCase
  EXAMPLES = Dir[File.expand_path("../../../docs/byte-form/examples/*", __dir__)].sort

  test "every published example's input produces its published bytes and hash" do
    results = EXAMPLES.map do |example|
      input = JSON.parse(File.read(File.join(example, "input.json")))
      bytes = AgreementEngine::ByteForm.encode(slug: input["slug"], number: input["number"], document: input["document"], values: input["values"], period: input["period"])
      [File.basename(example), bytes == File.binread(File.join(example, "bytes.json")), Digest::SHA256.hexdigest(bytes) == File.read(File.join(example, "sha256")).strip]
    end

    assert_equal [["blank-standing", true, true], ["with-values", true, true]], results
  end
end
