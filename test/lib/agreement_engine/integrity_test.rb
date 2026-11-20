require "test_helper"

class AgreementEngine::IntegrityTest < ActiveSupport::TestCase
  setup do
    page = KeystoneUi::Pages::Page.create!(name: "Terms", slug: "terms", document: KeystoneUi::Pages::Document.blank)
    page.publish
    @issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page.live_version, version: "2.0", effective_at: 1.day.ago)
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
  end

  test "the check lists issued versions and acceptances whose hashes disagree" do
    AgreementEngine::Document.where(id: @issued.id).update_all(content_hash: "0" * 64)
    acceptance = AgreementEngine::Acceptance.create!(signer: @user, document: @issued, content_hash: "f" * 64, accepted_at: Time.current)

    assert_equal ["Document #{@issued.code}: the frozen copy no longer produces its hash", "Acceptance #{acceptance.id}: its hash differs from document #{@issued.code}"],
      AgreementEngine::Integrity.problems
  end

  test "the check finds nothing when every hash agrees" do
    AgreementEngine::Acceptance.create!(signer: @user, document: @issued, content_hash: @issued.content_hash, accepted_at: Time.current)

    assert_empty AgreementEngine::Integrity.problems
  end
end
