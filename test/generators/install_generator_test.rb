# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/agreement_engine/install_generator"

class AgreementEngine::InstallGeneratorTest < Rails::Generators::TestCase
  tests AgreementEngine::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator_test", __dir__)

  setup do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(
      File.join(destination_root, "config/routes.rb"),
      "Rails.application.routes.draw do\nend\n"
    )
  end

  test "adds mount line to routes" do
    run_generator
    assert_file "config/routes.rb", /mount AgreementEngine::Engine, at: "\/legal"/
  end

  test "copies initializer" do
    run_generator
    assert_file "config/initializers/agreement_engine.rb", /AgreementEngine\.configure/
  end

  test "copies migrations" do
    run_generator
    # The documents migration keeps the name it was released under, so an
    # application that already ran it is not asked to run it again.
    assert_migration "db/migrate/create_fine_print_documents.rb"
  end

  test "copies the migration that renames the table" do
    run_generator
    assert_migration "db/migrate/rename_fine_print_tables_to_agreement_engine.rb"
  end
end
