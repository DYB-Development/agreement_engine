require "test_helper"

class AgreementEngine::Admin::DocumentsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(name: "Admin", email: "admin@test.com", admin: true)
    @non_admin = User.create!(name: "User", email: "user@test.com", admin: false)
  end

  # Auth tests

  test "unauthenticated user is redirected from admin" do
    get agreement_engine.admin_documents_path
    assert_response :redirect
  end

  test "non-admin user is redirected from admin" do
    sign_in(@non_admin)
    get agreement_engine.admin_documents_path
    assert_response :redirect
  end

  test "admin user can access admin" do
    sign_in(@admin)
    get agreement_engine.admin_documents_path
    assert_response :success
  end

  # CRUD tests (as admin)

  test "can view documents list" do
    sign_in(@admin)
    version = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Test content",
      effective_at: 1.day.ago
    )

    get agreement_engine.admin_documents_path
    assert_response :success
    assert_match version.version, response.body
  end

  test "can create new document" do
    sign_in(@admin)
    get agreement_engine.new_admin_document_path
    assert_response :success

    assert_difference "AgreementEngine::Document.count" do
      post agreement_engine.admin_documents_path, params: {
        document: {
          document_type: "terms_of_service",
          version: "2.0",
          content: "New terms content",
          summary: "Updated liability section"
        }
      }
    end

    assert_redirected_to agreement_engine.admin_document_path(AgreementEngine::Document.last)
  end

  test "can publish a draft by setting effective_at" do
    sign_in(@admin)
    version = AgreementEngine::Document.create!(
      document_type: "privacy_policy",
      version: "1.0",
      content: "Draft content",
      effective_at: nil
    )

    patch agreement_engine.admin_document_path(version), params: {
      document: {
        effective_at: Time.current
      }
    }

    assert_redirected_to agreement_engine.admin_document_path(version)
    version.reload
    assert version.effective_at.present?
  end

  test "can delete a document" do
    sign_in(@admin)
    version = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Content",
      effective_at: 1.day.ago
    )

    assert_difference "AgreementEngine::Document.count", -1 do
      delete agreement_engine.admin_document_path(version)
    end

    assert_redirected_to agreement_engine.admin_documents_path
  end
end
