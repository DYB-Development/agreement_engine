require "test_helper"
require "rake"

class SeedTaskTest < ActiveSupport::TestCase
  setup do
    Rake::Task.define_task(:environment)
    load File.expand_path("../../lib/tasks/agreement_engine.rake", __dir__) unless Rake::Task.task_defined?("agreement_engine:seed")
    Rake::Task["agreement_engine:seed"].reenable
  end

  teardown do
    AgreementEngine.config.electronic_consent = false
  end

  test "seeding issues the starting consent version when a host enables electronic consent" do
    AgreementEngine.config.electronic_consent = true

    capture_io { Rake::Task["agreement_engine:seed"].invoke }

    assert AgreementEngine::Document.current(:electronic_records_consent)
  end
end
