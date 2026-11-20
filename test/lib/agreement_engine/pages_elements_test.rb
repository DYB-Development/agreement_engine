require "test_helper"

class AgreementEngine::PagesElementsTest < ActiveSupport::TestCase
  test "the page builder offers a list element for legal documents" do
    assert_equal "List", KeystoneUi::Pages.catalog.find(:legal_list)&.name
  end
end
