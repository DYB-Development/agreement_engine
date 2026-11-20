# frozen_string_literal: true

require_relative "agreement_engine/version"
require "keystone_ui/pages"
require_relative "agreement_engine/configuration"
require_relative "agreement_engine/agreement"
require_relative "agreement_engine/document_type"
require_relative "agreement_engine/byte_form"
require_relative "agreement_engine/consent"

module AgreementEngine
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def document_type(key)
      config.registered_document_types.find { |type| type.key == key.to_sym }
    end
  end
end

require_relative "agreement_engine/engine"
require_relative "agreement_engine/signable"
require_relative "agreement_engine/enforceable"
