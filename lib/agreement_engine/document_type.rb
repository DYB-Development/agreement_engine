# frozen_string_literal: true

module AgreementEngine
  DocumentType = Data.define(:key, :title, :kind, :strength, :template, :prompts, :reading) do
    reading_settings = %i[seconds open]

    define_method(:initialize) do |key:, title:, kind:, strength:, template: nil, prompts: false, reading: nil|
      unknown = reading.to_h.keys - reading_settings
      raise ArgumentError, "Document type #{key} has an unknown reading setting: #{unknown.join(", ")}." if unknown.any?

      super(key:, title:, kind:, strength:, template:, prompts:, reading:)
    end

    def signature?
      strength.to_sym == :signature
    end

    def per_record?
      kind.to_sym == :per_record
    end

    def standing?
      !per_record?
    end

    def minimum_reading_seconds
      reading.to_h[:seconds].to_i
    end

    def requires_opening?
      reading.to_h[:open] == true
    end

    def to_param = key.to_s
  end
end
