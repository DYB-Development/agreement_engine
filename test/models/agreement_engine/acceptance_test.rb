require "test_helper"

class AgreementEngine::AcceptanceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
    @v1 = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "One", effective_at: 3.days.ago)
    @v2 = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "2.0", content: "Two", effective_at: 1.day.ago)
  end

  test "host code lists every version of a type a person accepted, oldest first" do
    @user.accept_version!(nil, @v1)
    @user.accept_version!(nil, @v2)

    assert_equal [@v1, @v2], @user.accepted_versions(:terms_of_service)
  end
end
