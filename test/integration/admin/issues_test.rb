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

  test "a type's earlier version still shows its own page after the next version is issued from a different page" do
    sign_in(@admin)
    earlier = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page.live_version, version: "1.0", effective_at: 2.days.ago)
    other_page = KeystoneUi::Pages::Page.create!(name: "Terms rewrite", slug: "terms-rewrite", document: KeystoneUi::Pages::Document.blank)
    other_page.publish
    AgreementEngine::Document.issue!(type: :terms_of_service, page_version: other_page.live_version, version: "2.0", effective_at: 1.day.ago)

    get agreement_engine.admin_document_path(earlier)

    assert_select "dd", text: "terms, version 1"
  end

  test "a numbered list in an issued version is drawn as a numbered list" do
    sign_in(@admin)
    document = KeystoneUi::Pages::Document.blank
    document["sections"][0]["rows"][0]["columns"][0]["elements"] << {"id" => "list-1", "key" => "legal_list", "fields" => {"style" => "numbered", "items" => [{"text" => "Pay on time"}, {"text" => "Keep it private"}]}}
    page = KeystoneUi::Pages::Page.create!(name: "Contract", slug: "contract", document: document)
    page.publish
    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page.live_version, version: "2.0", effective_at: 1.day.ago)

    get agreement_engine.admin_document_path(issued)

    assert_select "ol li", text: "Keep it private"
  end

  test "the issue form offers each published page version" do
    sign_in(@admin)

    get agreement_engine.new_admin_issue_path

    assert_select "option[value='#{@page.live_version.id}']", text: "Terms, version 1"
  end

  test "issuing a version label the type already has shows the form again with the reason" do
    sign_in(@admin)
    AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page.live_version, version: "2.0", effective_at: 1.day.ago)

    post agreement_engine.admin_issues_path, params: {issue: {document_type: "terms_of_service", page_version_id: @page.live_version.id, version: "2.0", effective_at: 1.day.ago}}

    assert_select "div", text: "Version has already been taken"
  end

  test "the documents list links to the issue form" do
    sign_in(@admin)

    get agreement_engine.admin_documents_path

    assert_select "a[href='#{agreement_engine.new_admin_issue_path}']", text: "Issue a version"
  end

  test "an admin viewing an issued version sees the acceptances recorded against it" do
    sign_in(@admin)
    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page.live_version, version: "2.0", effective_at: 1.day.ago)
    signer = User.create!(name: "Pat Lee", email: "pat@example.com")
    AgreementEngine::Acceptance.create!(signer: signer, person: {"name" => "Pat Lee", "email" => "pat@example.com"}, document: issued, accepted_at: 1.hour.ago, ip_address: "203.0.113.9")

    get agreement_engine.admin_document_path(issued)

    assert_select "td", text: "203.0.113.9"
  end

  test "the issue form offers the consent type once a host enables electronic consent" do
    AgreementEngine.config.electronic_consent = true
    sign_in(@admin)

    get agreement_engine.new_admin_issue_path

    assert_select "option[value='electronic_records_consent']", text: "Consent to Electronic Records"
  ensure
    AgreementEngine.config.electronic_consent = false
  end

  test "an admin gives a standing version a start and end date when issuing it" do
    sign_in(@admin)

    post agreement_engine.admin_issues_path, params: {issue: {document_type: "terms_of_service", page_version_id: @page.live_version.id, version: "2.0", effective_at: 1.day.ago, period_starts_on: "2027-01-01", period_ends_on: "2027-12-31"}}

    assert_equal({"starts_on" => "2027-01-01", "ends_on" => "2027-12-31"}, AgreementEngine::Document.current(:terms_of_service).frozen_copy["period"])
  end

  test "an admin gives a standing version a duration when issuing it" do
    sign_in(@admin)

    post agreement_engine.admin_issues_path, params: {issue: {document_type: "terms_of_service", page_version_id: @page.live_version.id, version: "2.0", effective_at: 1.day.ago, period_duration: "P1Y"}}

    assert_equal({"duration" => "P1Y"}, AgreementEngine::Document.current(:terms_of_service).frozen_copy["period"])
  end

  private

  def document_with_heading(text)
    document = KeystoneUi::Pages::Document.blank
    document["sections"][0]["rows"][0]["columns"][0]["elements"] << {"id" => "heading-1", "key" => "heading", "fields" => {"text" => text}}
    document
  end
end
