require "test_helper"

class AgreementEngine::EngineTest < ActiveSupport::TestCase
  test "installing the engine leaves other engines' controllers without the host app's route helpers" do
    assert_not ActionController::Base._helpers.include?(Rails.application.routes.url_helpers)
  end
end
