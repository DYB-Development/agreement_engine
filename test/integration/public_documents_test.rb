require "test_helper"

class PublicDocumentsTest < ActionDispatch::IntegrationTest
  setup do
    @terms_v1 = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Terms v1 content",
      effective_at: 2.days.ago
    )
    @privacy_v1 = AgreementEngine::Document.create!(
      document_type: "privacy_policy",
      version: "1.0",
      content: "Privacy v1 content",
      effective_at: 2.days.ago
    )
  end

  test "terms page loads successfully" do
    get agreement_engine.terms_path
    assert_response :success
    assert_match(/Version 1\.0/, response.body)
  end

  test "a public document page renders in the host's application layout" do
    get agreement_engine.terms_path

    assert_select "body[data-layout=application]"
  end

  test "privacy page loads successfully" do
    get agreement_engine.privacy_path
    assert_response :success
    assert_match(/Version 1\.0/, response.body)
  end

  test "terms page shows placeholder when no version published" do
    AgreementEngine::Document.destroy_all

    get agreement_engine.terms_path
    assert_response :success
    assert_match(/No terms of service have been published yet/, response.body)
  end

  test "privacy page shows placeholder when no version published" do
    AgreementEngine::Document.destroy_all

    get agreement_engine.privacy_path
    assert_response :success
    assert_match(/No privacy policy has been published yet/, response.body)
  end

  test "every registered standing type has a public page" do
    registered = AgreementEngine.config.document_types
    AgreementEngine.config.document_types = registered + [AgreementEngine::DocumentType.new(key: :nda, title: "Mutual NDA", kind: :standing, strength: :click_accept)]
    AgreementEngine::Document.create!(document_type: "nda", version: "1.0", content: "NDA content", effective_at: 1.day.ago)

    get agreement_engine.public_document_path(:nda)

    assert_select "h1", text: "Mutual NDA"
  ensure
    AgreementEngine.config.document_types = registered
  end
end
