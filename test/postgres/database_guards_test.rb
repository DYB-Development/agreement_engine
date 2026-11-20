require "test_helper"

class DatabaseGuardsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  class Guarded < ActiveRecord::Base
    self.abstract_class = true
  end

  setup do
    skip "AGREEMENT_ENGINE_POSTGRES_URL is not set" unless ENV["AGREEMENT_ENGINE_POSTGRES_URL"]
    Guarded.establish_connection(ENV["AGREEMENT_ENGINE_POSTGRES_URL"])
    @connection = Guarded.connection
    @connection.execute("DROP TABLE IF EXISTS agreement_engine_acceptances, agreement_engine_documents CASCADE")
    @connection.execute("CREATE TABLE agreement_engine_documents (id bigserial PRIMARY KEY, frozen_copy json, content_hash varchar, effective_at timestamp, page_version_id bigint)")
    @connection.execute("CREATE TABLE agreement_engine_acceptances (id bigserial PRIMARY KEY, ip_address varchar)")
    @connection.execute(AgreementEngine::DatabaseGuards::INSTALL)
    @connection.execute("INSERT INTO agreement_engine_documents (frozen_copy, content_hash, effective_at) VALUES ('{}', 'abc', now())")
    @connection.execute("INSERT INTO agreement_engine_acceptances (ip_address) VALUES ('203.0.113.9')")
  end

  teardown do
    @connection&.execute("DROP TABLE IF EXISTS agreement_engine_acceptances, agreement_engine_documents CASCADE")
  end

  test "the database rejects changing an acceptance in SQL" do
    assert_raises(ActiveRecord::StatementInvalid) { @connection.execute("UPDATE agreement_engine_acceptances SET ip_address = 'x'") }
  end

  test "the database rejects deleting an acceptance in SQL" do
    assert_raises(ActiveRecord::StatementInvalid) { @connection.execute("DELETE FROM agreement_engine_acceptances") }
  end

  test "the database rejects changing an issued version's hash in SQL" do
    assert_raises(ActiveRecord::StatementInvalid) { @connection.execute("UPDATE agreement_engine_documents SET content_hash = 'other'") }
  end

  test "the database rejects deleting an issued version in SQL" do
    assert_raises(ActiveRecord::StatementInvalid) { @connection.execute("DELETE FROM agreement_engine_documents") }
  end

  test "the database still lets an issued version lose its deleted page version" do
    @connection.execute("UPDATE agreement_engine_documents SET page_version_id = NULL")

    assert_equal 1, @connection.select_value("SELECT count(*) FROM agreement_engine_documents").to_i
  end
end
