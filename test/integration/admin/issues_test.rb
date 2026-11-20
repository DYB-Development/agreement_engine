require "test_helper"

class AgreementEngine::Admin::IssuesTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(name: "Admin", email: "admin@test.com", admin: true)
    @page = KeystoneUi::Pages::Page.create!(name: "Terms", slug: "terms", document: KeystoneUi::Pages::Document.blank)
    @page.publish
  end

  test "an admin issues a published page version as the next version of a standing type" do
    sign_in(@admin)

    post agreement_engine.admin_issues_path, params: {issue: {document_type: "terms_of_service", page_version_id: @page.live_version.id, version: "2.0", effective_at: 1.day.ago}}

    assert_equal @page.live_version, AgreementEngine::Document.current(:terms_of_service).page_version
  end
end
