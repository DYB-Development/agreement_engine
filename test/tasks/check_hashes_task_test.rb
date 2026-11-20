require "test_helper"
require "rake"

class CheckHashesTaskTest < ActiveSupport::TestCase
  setup do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    load File.expand_path("../../lib/tasks/agreement_engine.rake", __dir__) unless Rake::Task.task_defined?("agreement_engine:check_hashes")
    Rake::Task["agreement_engine:check_hashes"].reenable
  end

  test "the hash check task fails when it finds a hash that disagrees" do
    page = KeystoneUi::Pages::Page.create!(name: "Terms", slug: "terms", document: KeystoneUi::Pages::Document.blank)
    page.publish
    issued = AgreementEngine::Document.issue!(type: :terms_of_service, page_version: page.live_version, version: "2.0", effective_at: 1.day.ago)
    AgreementEngine::Document.where(id: issued.id).update_all(content_hash: "0" * 64)

    assert_raises(SystemExit) { capture_io { Rake::Task["agreement_engine:check_hashes"].invoke } }
  end
end
