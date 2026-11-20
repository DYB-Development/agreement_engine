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

  test "changing an issued version is refused and leaves it unchanged" do
    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: published_version(slug: "terms", title: "Terms"), version: "2.0", effective_at: 1.day.ago)

    issued.update(effective_at: 1.year.from_now)

    assert_in_delta 1.day.ago, issued.reload.effective_at, 5.seconds
  end

  test "an issued version whose frozen copy no longer produces its stored hash is not intact" do
    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: published_version(slug: "terms", title: "Terms"), version: "2.0", effective_at: 1.day.ago)
    AgreementEngine::Document.where(id: issued.id).update_all(content_hash: "0" * 64)

    assert_not issued.reload.hash_intact?
  end

  test "an issued version whose page version was edited or deleted since issue is marked as having moved" do
    page_version = published_version(slug: "terms", title: "Terms")
    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page_version, version: "2.0", effective_at: 1.day.ago)

    page_version.page.destroy

    assert issued.reload.source_moved?
  end

  test "issuing from a page holding an element that cannot be drawn as a PDF is refused naming the element" do
    KeystoneUi::Pages.catalog.register(key: :wiggle, name: "Wiggle", component: :ui_caption, fields: [{key: :text, label: "Text", kind: :text}])
    document = KeystoneUi::Pages::Document.blank
    document["sections"][0]["rows"][0]["columns"][0]["elements"] << {"id" => "w1", "key" => "wiggle", "fields" => {"text" => "Hi"}}
    page = KeystoneUi::Pages::Page.create!(name: "Odd", slug: "odd", document: document)
    page.publish

    error = assert_raises(ActiveRecord::RecordInvalid) { AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page.live_version, version: "9.0", effective_at: 1.day.ago) }

    assert_includes error.message, "The Wiggle element cannot be drawn as a PDF"
  ensure
    KeystoneUi::Pages.catalog.leave_out(:wiggle)
  end
end
