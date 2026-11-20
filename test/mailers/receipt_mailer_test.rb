require "test_helper"

class ReceiptMailerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    document = KeystoneUi::Pages::Document.blank
    page = KeystoneUi::Pages::Page.create!(name: "Terms", slug: "terms", document: document)
    page.publish
    @terms = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page.live_version, version: "2.0", effective_at: 1.day.ago)
    @user = User.create!(name: "Pat Lee", email: "pat@example.com")
    AgreementEngine.config.copy_email_types = [:terms_of_service]
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    AgreementEngine.config.copy_email_types = []
  end

  test "a person is emailed the PDF and the byte-form file when the host turns copies on for the type" do
    perform_enqueued_jobs do
      AgreementEngine::Acceptance.create!(signer: @user, document: @terms, content_hash: @terms.content_hash, accepted_at: Time.current, person: {"email" => "pat@example.com"})
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [["pat@example.com"], ["terms_of_service-2.0.pdf", "terms_of_service-2.0.json"]], [mail&.to, mail&.attachments&.map(&:filename)]
  end

  test "a copy that cannot be drawn leaves the acceptance recorded and reports the failure" do
    reported = []
    subscriber = Object.new.tap { |s| s.define_singleton_method(:report) { |error, **| reported << error.message } }
    Rails.error.subscribe(subscriber)
    original = AgreementEngine::Receipt.method(:pdf)
    AgreementEngine::Receipt.define_singleton_method(:pdf) { |_acceptance| raise KeystoneUi::Pages::PrintFailed, "cannot draw" }

    acceptance = perform_enqueued_jobs do
      AgreementEngine::Acceptance.create!(signer: @user, document: @terms, content_hash: @terms.content_hash, accepted_at: Time.current, person: {"email" => "pat@example.com"})
    end

    assert_equal [true, ["cannot draw"]], [AgreementEngine::Acceptance.exists?(acceptance.id), reported]
  ensure
    AgreementEngine::Receipt.define_singleton_method(:pdf, original) if original
    Rails.error.unsubscribe(subscriber) if subscriber
  end
end
