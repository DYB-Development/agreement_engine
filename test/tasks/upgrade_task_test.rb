require "test_helper"
require "rake"

class UpgradeTaskTest < ActiveSupport::TestCase
  setup do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    load File.expand_path("../../lib/tasks/agreement_engine.rake", __dir__) unless Rake::Task.task_defined?("agreement_engine:upgrade")
    Rake::Task["agreement_engine:upgrade"].reenable
    AgreementEngine::Document.create!(document_type: "privacy_policy", version: "1.0", content: "<div>Intro</div><table><tr><td>Cell</td></tr></table>", effective_at: 1.day.ago)
  end

  test "the upgrade task names each version holding content it could not carry over" do
    output, = capture_io { Rake::Task["agreement_engine:upgrade"].invoke("User") }

    assert_includes output, "privacy_policy 1.0 could not carry over: table"
  end
end
