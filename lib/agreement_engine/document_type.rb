# frozen_string_literal: true

module AgreementEngine
  DocumentType = Data.define(:key, :title, :kind, :strength) do
    def signature?
      strength.to_sym == :signature
    end
  end
end
