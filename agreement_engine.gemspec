# frozen_string_literal: true

require_relative "lib/agreement_engine/version"

Gem::Specification.new do |spec|
  spec.name = "agreement_engine"
  spec.version = AgreementEngine::VERSION
  spec.authors = ["tylercschneider"]
  spec.email = ["tylercschneider@gmail.com"]

  spec.summary = "Versioned legal document management for Rails"
  spec.description = "Track and enforce user acceptance of Terms of Service, Privacy Policy, and other legal agreements with versioned documents and audit trails."
  spec.homepage = "https://github.com/DYB-Development/agreement_engine"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.require_paths = ["lib"]

  # json 3 dropped the second argument ActiveSupport::JSON.decode passes it, so
  # every read of a json column raises until Rails ships a release that calls
  # the new interface.
  spec.add_dependency "json", "< 3"
  spec.add_dependency "rails", ">= 7.1"
end
