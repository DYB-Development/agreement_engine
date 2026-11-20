require "test_helper"

class AgreementEngine::IssuedDocumentTest < ActiveSupport::TestCase
  def published_version(slug:, title:)
    page = KeystoneUi::Pages::Page.create!(name: title, slug: slug, document: KeystoneUi::Pages::Document.blank.merge("title" => title))
    page.publish
    page.live_version
  end

  test "an issued version carries the SHA-256 of its page version's byte form" do
    page_version = published_version(slug: "terms", title: "Terms")

    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page_version, version: "2.0", effective_at: 1.day.ago)

    assert_equal AgreementEngine::ByteForm.digest(slug: "terms", number: 1, document: page_version.document), issued.content_hash
  end

  test "issuing the same page content twice gives the same hash" do
    page_version = published_version(slug: "terms", title: "Terms")

    first = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page_version, version: "2.0", effective_at: 1.day.ago)
    second = AgreementEngine::Document.issue!(type: :privacy_policy, page_version: page_version, version: "2.0", effective_at: 1.day.ago)

    assert_equal first.content_hash, second.content_hash
  end

  test "publishing a page again leaves the issued version in force until an admin issues the new one" do
    page_version = published_version(slug: "terms", title: "Terms")
    AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page_version, version: "1.0", effective_at: 1.day.ago)

    page_version.page.edit(page_version.page.document.merge("title" => "Terms, revised"))
    page_version.page.publish

    assert_equal 1, AgreementEngine::Document.current(:terms_of_service).frozen_copy["number"]
  end
end
