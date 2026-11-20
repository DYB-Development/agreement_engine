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

  test "an issued version keeps showing its original text after its page is deleted" do
    sign_in(@admin)
    page = KeystoneUi::Pages::Page.create!(name: "Privacy", slug: "privacy", document: document_with_heading("Our privacy promise"))
    page.publish
    issued = AgreementEngine::Document.issue!(type: :privacy_policy, page_version: page.live_version, version: "2.0", effective_at: 1.day.ago)
    page.destroy

    get agreement_engine.admin_document_path(issued)

    assert_includes response.body, "Our privacy promise"
  end

  test "an issued version shows its SHA-256 hash" do
    sign_in(@admin)
    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page.live_version, version: "2.0", effective_at: 1.day.ago)

    get agreement_engine.admin_document_path(issued)

    assert_includes response.body, issued.content_hash
  end

  test "deleting an issued version is refused with a message saying it is frozen" do
    sign_in(@admin)
    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page.live_version, version: "2.0", effective_at: 1.day.ago)

    delete agreement_engine.admin_document_path(issued)

    assert_equal "Issued versions are frozen and cannot be changed or deleted.", flash[:alert]
  end

  test "editing an issued version is refused and leaves it unchanged" do
    sign_in(@admin)
    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page.live_version, version: "2.0", effective_at: 1.day.ago)

    patch agreement_engine.admin_document_path(issued), params: {document: {effective_at: 1.year.from_now}}

    assert_in_delta 1.day.ago, issued.reload.effective_at, 5.seconds
  end

  private

  def document_with_heading(text)
    document = KeystoneUi::Pages::Document.blank
    document["sections"][0]["rows"][0]["columns"][0]["elements"] << {"id" => "heading-1", "key" => "heading", "fields" => {"text" => text}}
    document
  end
end
