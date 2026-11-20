require "test_helper"

class AgreementEngine::UpgradeTest < ActiveSupport::TestCase
  setup do
    @terms_v1 = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "<h1>Terms</h1><div>Be <strong>kind</strong>, see <a href=\"https://example.com\">this</a> and <em>that</em>.</div><ul><li>One</li><li>Two</li></ul>", effective_at: 3.days.ago)
    @terms_v2 = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "2.0", content: "<div>Terms two</div>", effective_at: 1.day.ago)
    @draft = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "3.0", content: "<div>Draft</div>", effective_at: nil)
    @privacy = AgreementEngine::Document.create!(document_type: "privacy_policy", version: "1.0", content: "<div>Privacy</div>", effective_at: 2.days.ago)
    @user = User.create!(name: "Pat Lee", email: "pat@example.com", accepted_terms_of_service_version_id: @terms_v2.id, accepted_privacy_policy_version_id: @privacy.id)
    User.create!(name: "No One", email: "none@example.com")
  end

  test "the upgrade makes one page per document type and one published version per dated version" do
    AgreementEngine::Upgrade.run

    assert_equal({"terms_of_service" => [1, 2], "privacy_policy" => [1]},
      KeystoneUi::Pages::Page.all.to_h { |page| [page.slug.delete_prefix("agreement-").tr("-", "_"), page.versions.map(&:number)] })
  end

  test "the upgrade lists each version holding content it could not carry over" do
    AgreementEngine::Document.create!(document_type: "privacy_policy", version: "2.0", content: "<div>Intro</div><table><tr><td>Cell</td></tr></table>", effective_at: 1.hour.ago)

    report = AgreementEngine::Upgrade.run

    assert_equal [["privacy_policy", "2.0", ["table"]]], report.left_out
  end

  test "each carried-over version keeps its label and effective date and is issued, frozen and hashed" do
    effective_at = @terms_v1.effective_at

    AgreementEngine::Upgrade.run

    upgraded = @terms_v1.reload
    copy = upgraded.frozen_copy
    assert_equal ["1.0", effective_at, AgreementEngine::ByteForm.digest(slug: copy["slug"], number: copy["number"], document: copy["document"])],
      [upgraded.version, upgraded.effective_at, upgraded.content_hash]
  end

  test "the upgrade carries over one acceptance for each user's stored accepted version" do
    AgreementEngine::Upgrade.run(signer_class: User)

    assert_equal [[@user, @terms_v2, true], [@user, @privacy, true]].sort_by { |row| row[1].id },
      AgreementEngine::Acceptance.order(:document_id).map { |acceptance| [acceptance.signer, acceptance.document, acceptance.carried_over] }
  end
end
