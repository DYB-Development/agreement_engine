# frozen_string_literal: true

module AgreementEngine
  DocumentType = Data.define(:key, :title, :kind, :strength, :template, :prompts) do
    def initialize(key:, title:, kind:, strength:, template: nil, prompts: false)
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

    def to_param = key.to_s
  end
end
