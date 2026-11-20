# frozen_string_literal: true

require "digest"
require "json"

module AgreementEngine
  module ByteForm
    VERSION = 1

    module_function

    def encode(slug:, number:, document:, values: {}, period: nil)
      JSON.generate(sorted({"slug" => slug, "number" => number, "document" => document, "values" => values, "period" => period}))
    end

    def digest(**content)
      Digest::SHA256.hexdigest(encode(**content))
    end

    def sorted(value)
      case value
      when Hash then value.sort_by { |key, _| key.to_s }.to_h { |key, nested| [key.to_s, sorted(nested)] }
      when Array then value.map { |nested| sorted(nested) }
      else value
      end
    end
  end
end
