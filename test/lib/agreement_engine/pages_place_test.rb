require "test_helper"

class AgreementEngine::PagesPlaceTest < ActiveSupport::TestCase
  setup do
    @places = KeystoneUi::Pages.places
    KeystoneUi::Pages.register_place("legal", label: "Legal documents", slug: false)
    AgreementEngine.config.pages_place = "legal"
    AgreementEngine.config.electronic_consent = true
  end

  teardown do
    AgreementEngine.config.pages_place = nil
    AgreementEngine.config.electronic_consent = false
    KeystoneUi::Pages.places = @places
  end

  test "the gem's starting pages go in the place a host that registers places names" do
    AgreementEngine::Consent.seed!

    assert_equal "legal", AgreementEngine::Document.current(:electronic_records_consent).page_version.page.place
  end

  test "the upgrade's pages go in the place the host names" do
    AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "<div>Terms</div>", effective_at: 1.day.ago)

    AgreementEngine::Upgrade.run

    assert_equal ["legal"], KeystoneUi::Pages::Page.distinct.pluck(:place)
  end
end
