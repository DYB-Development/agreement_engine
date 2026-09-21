require "test_helper"

class AgreementEngine::DocumentTest < ActiveSupport::TestCase
  test "valid with all required attributes" do
    doc = AgreementEngine::Document.new(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Terms content here"
    )
    assert doc.valid?
  end

  test "requires document_type" do
    doc = AgreementEngine::Document.new(version: "1.0", content: "Content")
    assert_not doc.valid?
    assert_includes doc.errors[:document_type], "can't be blank"
  end

  test "requires version" do
    doc = AgreementEngine::Document.new(document_type: "terms_of_service", content: "Content")
    assert_not doc.valid?
    assert_includes doc.errors[:version], "can't be blank"
  end

  test "requires content" do
    doc = AgreementEngine::Document.new(document_type: "terms_of_service", version: "1.0")
    assert_not doc.valid?
    assert_includes doc.errors[:content], "can't be blank"
  end

  test "version must be unique within document_type" do
    AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "First version"
    )

    duplicate = AgreementEngine::Document.new(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Duplicate version"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:version], "has already been taken"
  end

  test "published scope returns versions with effective_at in past" do
    published = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Published",
      effective_at: 1.day.ago
    )
    draft = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "2.0",
      content: "Draft",
      effective_at: nil
    )

    assert_includes AgreementEngine::Document.published, published
    assert_not_includes AgreementEngine::Document.published, draft
  end

  test "draft scope returns versions without effective_at" do
    published = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Published",
      effective_at: 1.day.ago
    )
    draft = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "2.0",
      content: "Draft",
      effective_at: nil
    )

    assert_includes AgreementEngine::Document.draft, draft
    assert_not_includes AgreementEngine::Document.draft, published
  end

  test "current returns most recently effective version for document_type" do
    AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "1.0",
      content: "Old version",
      effective_at: 2.days.ago
    )
    current_version = AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "2.0",
      content: "Current version",
      effective_at: 1.day.ago
    )
    AgreementEngine::Document.create!(
      document_type: "terms_of_service",
      version: "3.0",
      content: "Future version",
      effective_at: 1.day.from_now
    )

    assert_equal current_version, AgreementEngine::Document.current(:terms_of_service)
  end

  test "published? returns true when effective_at is in the past" do
    doc = AgreementEngine::Document.new(effective_at: 1.day.ago)
    assert doc.published?
  end

  test "published? returns false when effective_at is nil" do
    doc = AgreementEngine::Document.new(effective_at: nil)
    assert_not doc.published?
  end

  test "published? returns false when effective_at is in the future" do
    doc = AgreementEngine::Document.new(effective_at: 1.day.from_now)
    assert_not doc.published?
  end
end
