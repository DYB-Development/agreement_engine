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

  test "a person who withdrew consent no longer holds it" do
    AgreementEngine.config.electronic_consent = true
    consent_version = AgreementEngine::Consent.seed!
    user = User.create!(name: "Pat Lee", email: "pat@example.com")
    consent = AgreementEngine::Acceptance.create!(signer: user, document: consent_version, accepted_at: 1.day.ago)
    AgreementEngine::ConsentWithdrawal.create!(acceptance: consent, withdrawn_at: 1.hour.ago)

    assert_not user.holds_consent?
  end

  test "a person who consented under an earlier consent version does not hold consent under the current one" do
    AgreementEngine.config.electronic_consent = true
    first = AgreementEngine::Consent.seed!
    user = User.create!(name: "Pat Lee", email: "pat@example.com")
    AgreementEngine::Acceptance.create!(signer: user, document: first, accepted_at: 2.days.ago)
    first.update_column(:effective_at, 3.days.ago)
    AgreementEngine::Document.issue!(type: :electronic_records_consent, page_version: first.page_version, version: "2.0", effective_at: 1.day.ago)

    assert_not user.holds_consent?
  end
end
