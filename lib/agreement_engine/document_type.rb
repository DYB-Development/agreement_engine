# frozen_string_literal: true

module AgreementEngine
  DocumentType = Data.define(:key, :title, :kind, :strength, :template, :prompts, :reading) do
    def initialize(key:, title:, kind:, strength:, template: nil, prompts: false, reading: nil)
      check_reading(key, kind, reading.to_h)
      super
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

    private

    def check_reading(key, kind, reading)
      unknown = reading.keys - %i[seconds open]
      raise ArgumentError, "Document type #{key} has an unknown reading setting: #{unknown.join(", ")}." if unknown.any?
      raise ArgumentError, "Document type #{key} cannot require opening, because per-record documents have no public page." if reading[:open] && kind.to_sym == :per_record

      seconds = reading[:seconds]
      raise ArgumentError, "Document type #{key} needs its minimum reading time as a positive whole number of seconds." unless seconds.nil? || (seconds.is_a?(Integer) && seconds.positive?)
    end
  end
end
