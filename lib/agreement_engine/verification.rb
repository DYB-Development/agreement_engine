# frozen_string_literal: true

require "digest"

module AgreementEngine
  module Verification
    module_function

    def matches?(bytes, hash_value)
      Digest::SHA256.hexdigest(bytes.to_s) == hash_value.to_s.strip.downcase
    end
  end
end
