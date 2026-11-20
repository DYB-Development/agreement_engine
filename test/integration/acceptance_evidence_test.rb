require "test_helper"

class AcceptanceEvidenceTest < ActionDispatch::IntegrationTest
  setup do
    page = KeystoneUi::Pages::Page.create!(name: "Terms", slug: "terms", document: KeystoneUi::Pages::Document.blank)
    page.publish
    @terms = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page.live_version, version: "2.0", effective_at: 1.day.ago)
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
    sign_in @user
  end

  def accept_terms
    patch agreement_engine.agreement_path(:terms_of_service), headers: {"User-Agent" => "TestBrowser/1.0"}, env: {"REMOTE_ADDR" => "203.0.113.9"}
    AgreementEngine::Acceptance.last
  end

  test "accepting records the issued version's hash" do
    assert_equal @terms.content_hash, accept_terms.content_hash
  end

  test "accepting records the IP address" do
    assert_equal "203.0.113.9", accept_terms.ip_address
  end

  test "accepting records the browser" do
    assert_equal "TestBrowser/1.0", accept_terms.user_agent
  end

  test "accepting records the statement shown beside the button" do
    assert_equal "Before you can proceed, you must read and accept the new Terms Of Service.", accept_terms.statement
  end
end
