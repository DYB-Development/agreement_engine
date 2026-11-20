require "test_helper"

class AgreementEngine::ConsentTest < ActiveSupport::TestCase
  teardown do
    AgreementEngine.config.electronic_consent = false
  end

  test "a host that enables electronic consent gets the consent document type" do
    AgreementEngine.config.electronic_consent = true

    assert_equal "Consent to Electronic Records", AgreementEngine.document_type(:electronic_records_consent)&.title
  end

  test "the starting consent page covers paper copies, withdrawing consent and what a person needs" do
    AgreementEngine.config.electronic_consent = true

    AgreementEngine::Consent.seed!

    headings = AgreementEngine::Document.current(:electronic_records_consent).frozen_copy["document"]["sections"]
      .flat_map { |section| section["rows"] }.flat_map { |row| row["columns"] }.flat_map { |column| column["elements"] }
      .select { |element| element["key"] == "heading" }.map { |element| element["fields"]["text"] }
    assert_equal ["Paper copies", "Withdrawing your consent", "What you need to open and keep records"], headings.drop(1)
  end
end
