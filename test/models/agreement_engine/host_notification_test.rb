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

  test "the handler is told the type, version, person, account, strength and host record" do
    AgreementEngine::Acceptance.create!(signer: @user, document: @terms, accepted_at: Time.current, person: {"name" => "Pat Lee"}, account: {"name" => "Acme"})

    event = @told.last
    assert_equal [:terms_of_service, @terms, {"name" => "Pat Lee"}, {"name" => "Acme"}, :click_accept, nil], [event.document_type, event.document, event.person, event.account, event.strength, event.subject]
  end

  test "the handler is told the reading evidence kept with the acceptance" do
    AgreementEngine::Acceptance.create!(signer: @user, document: @terms, accepted_at: Time.current, reading: {"minimum_seconds" => 30, "measured_seconds" => 42})

    assert_equal({"minimum_seconds" => 30, "measured_seconds" => 42}, @told.last.reading)
  end

  test "the handler is told when a signature is the first one on a record's document" do
    record_document = AgreementEngine::Document.create!(document_type: "plan_sign_off", version: "1", content: "Plan", effective_at: Time.current, subject: @user)

    AgreementEngine::Acceptance.create!(signer: @user, document: record_document, accepted_at: Time.current, strength: "signature")
    AgreementEngine::Acceptance.create!(signer: User.create!(name: "Second Signer", email: "second@example.com"), document: record_document, accepted_at: Time.current, strength: "signature")

    assert_equal [true, false], @told.map(&:first_signature?)
  end

  test "a handler that raises leaves the acceptance saved and reports the error" do
    AgreementEngine.config.acceptance_handler = ->(_event) { raise "host is down" }
    reported = []
    subscriber = Object.new.tap { |s| s.define_singleton_method(:report) { |error, **| reported << error.message } }
    Rails.error.subscribe(subscriber)

    acceptance = AgreementEngine::Acceptance.create!(signer: @user, document: @terms, accepted_at: Time.current)

    assert_equal [true, ["host is down"]], [AgreementEngine::Acceptance.exists?(acceptance.id), reported]
  ensure
    Rails.error.unsubscribe(subscriber)
  end
end
