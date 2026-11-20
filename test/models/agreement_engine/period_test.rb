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
end
