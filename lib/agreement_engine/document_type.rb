# frozen_string_literal: true

module AgreementEngine
  DocumentType = Data.define(:key, :title, :kind, :strength, :template) do
    def initialize(key:, title:, kind:, strength:, template: nil)
      super
    end

    def signature?
      strength.to_sym == :signature
    end

    def per_record?
      kind.to_sym == :per_record
    end
  end
end
