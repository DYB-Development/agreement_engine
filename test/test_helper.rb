# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"

# Clear engine migration paths — we use schema.rb for the in-memory DB
ActiveRecord::Migrator.migrations_paths = []

require "rails/test_help"

# In-memory SQLite needs schema loaded on each boot
ActiveRecord::Schema.verbose = false
load File.expand_path("dummy/db/schema.rb", __dir__)

class ActiveSupport::TestCase
  setup do
    AgreementEngine::Document.destroy_all
    User.destroy_all
  end
end

class ActionDispatch::IntegrationTest
  def sign_in(user)
    post "/test_sign_in", params: {user_id: user.id}
  end
end
