require "test_helper"

class AgreementEngine::SignableTest < ActiveSupport::TestCase
  setup do
    @terms_v1 = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Terms v1",
      effective_at: 2.days.ago
    )
    @user = User.create!(name: "Test User", email: "test@example.com")
  end

  test "needs_acceptance? returns true when user has not accepted current version" do
    assert @user.needs_acceptance?(:terms_of_service)
  end

  test "needs_acceptance? returns false when user has accepted current version" do
    AgreementEngine::Acceptance.create!(signer: @user, document: @terms_v1, accepted_at: Time.current)
    assert_not @user.needs_acceptance?(:terms_of_service)
  end

  test "accept_version! records an acceptance of the version" do
    @user.accept_version!(@terms_v1)

    assert AgreementEngine::Acceptance.exists?(signer: @user, document: @terms_v1)
  end

  test "accept_version! keeps when and where the document was opened" do
    opened = {opened_on: "public_page", opened_at: "2026-11-23T09:00:00Z"}

    assert_equal({"opened_on" => "public_page", "opened_at" => "2026-11-23T09:00:00Z"}, @user.accept_version!(@terms_v1, reading: opened).reading)
  end

  test "accept_version! of a type requiring opening, with no opening passed, fails naming the type" do
    with_terms_requiring_opening do
      error = assert_raises(ArgumentError) { @user.accept_version!(@terms_v1) }

      assert_equal "Document type terms_of_service requires opening, and no opening of this version was passed.", error.message
    end
  end

  test "accept_version! of a type requiring opening, with no opening passed, saves no acceptance" do
    with_terms_requiring_opening do
      assert_raises(ArgumentError) { @user.accept_version!(@terms_v1) }
    end

    assert_not AgreementEngine::Acceptance.exists?(signer: @user, document: @terms_v1)
  end

  test "accept_version! of a type requiring opening, passed an opening of another version, fails naming the type" do
    opened = {opened_on: "public_page", opened_at: "2026-11-23T09:00:00Z", version_id: @terms_v1.id + 1}

    with_terms_requiring_opening do
      error = assert_raises(ArgumentError) { @user.accept_version!(@terms_v1, reading: opened) }

      assert_equal "Document type terms_of_service requires opening, and no opening of this version was passed.", error.message
    end
  end

  private

  def with_terms_requiring_opening
    registered = AgreementEngine.config.document_types
    AgreementEngine.config.document_types = [AgreementEngine::DocumentType.new(key: :terms_of_service, title: "Terms Of Service", kind: :standing, strength: :click_accept, reading: {open: true})]
    yield
  ensure
    AgreementEngine.config.document_types = registered
  end
end
