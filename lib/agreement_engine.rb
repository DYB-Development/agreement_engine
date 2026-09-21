# frozen_string_literal: true

require_relative "agreement_engine/version"
require_relative "agreement_engine/configuration"
require_relative "agreement_engine/agreement"

module AgreementEngine
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end
  end
end

require_relative "agreement_engine/engine"
require_relative "agreement_engine/signable"
require_relative "agreement_engine/enforceable"
