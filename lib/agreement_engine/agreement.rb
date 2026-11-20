# frozen_string_literal: true

module AgreementEngine
  Agreement = Data.define(:id, :title, :version_column, :document_type, :prompt_when_updated) do
    def current_version
      AgreementEngine::Document.current(document_type)
    end

    def accepted_by?(user)
      current = current_version
      return true unless current
      AgreementEngine::Acceptance.exists?(signer: user, document: current)
    end

    def not_accepted_by?(user)
      !accepted_by?(user)
    end

    def to_document_type
      DocumentType.new(key: document_type.to_sym, title: title, kind: :standing, strength: :click_accept)
    end

    def to_param = id

    def to_partial_path = "agreement_engine/agreements/#{id}"
  end
end
