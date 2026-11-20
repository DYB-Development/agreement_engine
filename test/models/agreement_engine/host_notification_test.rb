require "test_helper"

class AgreementEngine::HostNotificationTest < ActiveSupport::TestCase
  setup do
    @told = []
    AgreementEngine.config.acceptance_handler = ->(event) { @told << event }
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
    @terms = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "Terms", effective_at: 1.day.ago)
  end

  teardown do
    AgreementEngine.config.acceptance_handler = nil
  end

  test "the host's handler is told about an acceptance once it is saved" do
    acceptance = AgreementEngine::Acceptance.create!(signer: @user, document: @terms, accepted_at: Time.current)

    assert_equal [acceptance], @told.map(&:acceptance)
  end
end
