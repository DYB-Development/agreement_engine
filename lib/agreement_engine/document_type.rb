# frozen_string_literal: true

module AgreementEngine
  DocumentType = Data.define(:key, :title, :kind, :strength, :template, :prompts, :reading) do
    def initialize(key:, title:, kind:, strength:, template: nil, prompts: false, reading: nil)
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

    def to_param = key.to_s
  end
end
