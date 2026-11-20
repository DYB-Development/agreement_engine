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

  test "each agreement a host lists the existing way is a registered standing click-accept type" do
    assert_equal AgreementEngine::DocumentType.new(key: :terms_of_service, title: "Terms Of Service", kind: :standing, strength: :click_accept),
      AgreementEngine.document_type(:terms_of_service)
  end

  test "a host marks a document type as needing a signature by setting its strength" do
    assert AgreementEngine::DocumentType.new(key: :sow, title: "Statement of work", kind: :standing, strength: :signature).signature?
  end
end
