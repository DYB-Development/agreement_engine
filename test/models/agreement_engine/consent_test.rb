require "test_helper"

class AgreementEngine::ConsentTest < ActiveSupport::TestCase
  teardown do
    AgreementEngine.config.electronic_consent = false
  end

  test "a host that enables electronic consent gets the consent document type" do
    AgreementEngine.config.electronic_consent = true

    assert_equal "Consent to Electronic Records", AgreementEngine.document_type(:electronic_records_consent)&.title
  end
end
