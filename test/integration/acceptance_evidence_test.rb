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

  test "accepting records the text of the button pressed" do
    assert_equal "I Accept", accept_terms.button_text
  end

  test "accepting records the versions of agreement_engine and keystone_ui-pages in use" do
    acceptance = accept_terms

    assert_equal [AgreementEngine::VERSION, KeystoneUi::Pages::VERSION], [acceptance.engine_version, acceptance.pages_version]
  end

  test "accepting records the time of acceptance" do
    accepted = @terms.effective_at.change(usec: 0) + 1.hour
    travel_to accepted do
      assert_equal accepted, accept_terms.accepted_at
    end
  end

  test "accepting records the person's id, name and email as they were at that moment" do
    acceptance = accept_terms
    @user.update!(name: "Pat Renamed", email: "renamed@example.com")

    assert_equal({"id" => @user.id, "name" => "Pat Lee", "email" => "pat@example.com"}, acceptance.reload.person)
  end

  test "accepting records the account the host's evidence hook names" do
    with_evidence_hook(->(_controller, _signer) { {account: {"id" => 7, "name" => "Acme"}} }) do
      assert_equal({"id" => 7, "name" => "Acme"}, accept_terms.account)
    end
  end

  test "accepting adds the person details a host's evidence hook supplies" do
    with_evidence_hook(->(_controller, _signer) { {person: {"phone" => "555-0100"}} }) do
      assert_equal "555-0100", accept_terms.person["phone"]
    end
  end

  test "accepting records how the session signed in as a host's evidence hook reports it" do
    with_evidence_hook(->(_controller, _signer) { {sign_in: {"methods" => ["password", "totp"]}} }) do
      assert_equal({"methods" => ["password", "totp"]}, accept_terms.sign_in)
    end
  end

  test "accepting writes to no column on the host's user table" do
    accept_terms

    assert_nil @user.reload.accepted_terms_of_service_version_id
  end

  test "a person sees the usual result when the host's handler raises" do
    AgreementEngine.config.acceptance_handler = ->(_event) { raise "host is down" }

    accept_terms

    assert_response :see_other
  ensure
    AgreementEngine.config.acceptance_handler = nil
  end

  test "the accept page shows the period the version covers" do
    page = KeystoneUi::Pages::Page.create!(name: "Terms 3", slug: "terms-3", document: KeystoneUi::Pages::Document.blank)
    page.publish
    AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page.live_version, version: "3.0", effective_at: 1.hour.ago, period: {"duration" => "P1Y"})

    get agreement_engine.agreement_path(:terms_of_service)

    assert_select "p", text: "Period: 1 year from acceptance"
  end

  test "the accept page draws the issued version from its frozen copy" do
    document = KeystoneUi::Pages::Document.blank
    document["sections"][0]["rows"][0]["columns"][0]["elements"] << {"id" => "h1", "key" => "heading", "fields" => {"text" => "Issued wording"}}
    page = KeystoneUi::Pages::Page.create!(name: "Terms 4", slug: "terms-4", document: document)
    page.publish
    AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page.live_version, version: "4.0", effective_at: 1.hour.ago)
    page.edit(KeystoneUi::Pages::Document.blank)

    get agreement_engine.agreement_path(:terms_of_service)

    assert_includes response.body, "Issued wording"
  end

  private

  def with_evidence_hook(hook)
    AgreementEngine.config.evidence_method = hook
    yield
  ensure
    AgreementEngine.config.evidence_method = nil
  end
end
