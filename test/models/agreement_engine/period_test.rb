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
end
