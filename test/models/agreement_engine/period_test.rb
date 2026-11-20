require "test_helper"

class AgreementEngine::PeriodTest < ActiveSupport::TestCase
  setup do
    page = KeystoneUi::Pages::Page.create!(name: "Contract", slug: "contract", document: KeystoneUi::Pages::Document.blank)
    page.publish
    @page_version = page.live_version
  end

  test "a different period gives an issued version a different hash" do
    year = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page_version, version: "1.0", effective_at: 1.day.ago, period: {"duration" => "P1Y"})
    month = AgreementEngine::Document.issue!(type: :privacy_policy, page_version: @page_version, version: "1.0", effective_at: 1.day.ago, period: {"duration" => "P1M"})

    assert_not_equal year.content_hash, month.content_hash
  end

  test "an acceptance of a document with a duration records a period starting when it was accepted" do
    document = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page_version, version: "1.0", effective_at: 1.day.ago, period: {"duration" => "P1Y"})
    user = User.create!(name: "Pat Lee", email: "pat@example.com")

    acceptance = AgreementEngine::Acceptance.create!(signer: user, document: document, accepted_at: Time.utc(2026, 11, 20, 10))

    assert_equal [Date.new(2026, 11, 20), Date.new(2027, 11, 20)], [acceptance.period_starts_on, acceptance.period_ends_on]
  end

  test "an acceptance of a document with fixed dates records those dates" do
    document = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page_version, version: "1.0", effective_at: 1.day.ago, period: {"starts_on" => "2027-01-01", "ends_on" => "2027-06-30"})
    user = User.create!(name: "Pat Lee", email: "pat@example.com")

    acceptance = AgreementEngine::Acceptance.create!(signer: user, document: document, accepted_at: Time.utc(2026, 11, 20, 10))

    assert_equal [Date.new(2027, 1, 1), Date.new(2027, 6, 30)], [acceptance.period_starts_on, acceptance.period_ends_on]
  end

  def accept(document, user, at)
    AgreementEngine::Acceptance.create!(signer: user, document: document, accepted_at: at, account: {"id" => 7, "name" => "Acme"})
  end

  test "an agreement is in force inside its period and not before it starts or after it ends" do
    document = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page_version, version: "1.0", effective_at: 1.day.ago, period: {"starts_on" => "2027-01-01", "ends_on" => "2027-06-30"})
    user = User.create!(name: "Pat Lee", email: "pat@example.com")
    acceptance = accept(document, user, Time.utc(2026, 11, 20))

    assert_equal [[], [acceptance], []],
      [Date.new(2026, 12, 31), Date.new(2027, 3, 1), Date.new(2027, 7, 1)].map { |day| AgreementEngine.in_force(person: user, on: day) }
  end

  test "an agreement with no period is in force from its acceptance onward" do
    document = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: @page_version, version: "1.0", effective_at: 1.day.ago)
    user = User.create!(name: "Pat Lee", email: "pat@example.com")
    acceptance = accept(document, user, Time.utc(2026, 11, 20))

    assert_equal [[], [acceptance]], [Date.new(2026, 11, 19), Date.new(2030, 1, 1)].map { |day| AgreementEngine.in_force(person: user, on: day) }
  end

  test "host code asks which agreements are in force for an account or for a host record" do
    user = User.create!(name: "Pat Lee", email: "pat@example.com")
    record_document = AgreementEngine::Document.issue!(type: :quote, page_version: @page_version, version: "1", effective_at: 1.day.ago, subject: user)
    acceptance = accept(record_document, user, Time.utc(2026, 11, 20))

    assert_equal [[acceptance], [acceptance]], [AgreementEngine.in_force(account_id: 7, on: Date.new(2027, 1, 1)), AgreementEngine.in_force(record: user, on: Date.new(2027, 1, 1))]
  end
end
