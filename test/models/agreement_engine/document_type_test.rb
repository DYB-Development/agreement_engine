require "test_helper"

class AgreementEngine::DocumentTypeTest < ActiveSupport::TestCase
  setup do
    @registered = AgreementEngine.config.document_types
  end

  teardown do
    AgreementEngine.config.document_types = @registered
  end

  test "a host registers a document type with a key, title, kind and strength" do
    nda = AgreementEngine::DocumentType.new(key: :nda, title: "Mutual NDA", kind: :standing, strength: :click_accept)
    AgreementEngine.config.document_types = [nda]

    assert_equal nda, AgreementEngine.document_type(:nda)
  end
end
