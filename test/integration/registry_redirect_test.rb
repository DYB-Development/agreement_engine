require "test_helper"

class RegistryRedirectTest < ActionDispatch::IntegrationTest
  setup do
    @registered = AgreementEngine.config.document_types
    AgreementEngine.config.document_types = @registered + [AgreementEngine::DocumentType.new(key: :nda, title: "Mutual NDA", kind: :standing, strength: :click_accept, prompts: true)]
    AgreementEngine::Document.create!(document_type: "nda", version: "1.0", content: "NDA", effective_at: 1.day.ago)
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
    %w[terms_of_service privacy_policy].each do |type|
      AgreementEngine::Acceptance.create!(signer: @user, document: AgreementEngine::Document.create!(document_type: type, version: "1.0", content: type, effective_at: 1.day.ago), accepted_at: Time.current)
    end
    sign_in @user
  end

  teardown do
    AgreementEngine.config.document_types = @registered
  end

  test "a registered type that prompts redirects a person who has not accepted its current version" do
    get "/"

    assert_redirected_to agreement_engine.agreement_path(:nda)
  end
end
