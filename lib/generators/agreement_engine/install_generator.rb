# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module AgreementEngine
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Installs AgreementEngine: adds route, copies initializer and migrations."

      def mount_engine
        route 'mount AgreementEngine::Engine, at: "/legal"'
      end

      def copy_initializer
        template "initializer.rb", "config/initializers/agreement_engine.rb"
      end

      def copy_migrations
        migrations_dir = AgreementEngine::Engine.root.join("db/migrate")
        Dir[migrations_dir.join("*.rb")].sort.each do |migration|
          filename = File.basename(migration).sub(/^\d+_/, "")
          migration_template migration, "db/migrate/#{filename}"
        end
      end
    end
  end
end
