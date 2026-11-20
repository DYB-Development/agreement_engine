# frozen_string_literal: true

module AgreementEngine
  module Integrity
    module_function

    def problems
      document_problems + acceptance_problems
    end

    def document_problems
      Document.where.not(content_hash: nil).find_each.reject(&:hash_intact?).map do |document|
        "Document #{document.code}: the frozen copy no longer produces its hash"
      end
    end

    def acceptance_problems
      Acceptance.includes(:document).where.not(content_hash: nil).find_each.select { |acceptance| acceptance.content_hash != acceptance.document.content_hash }.map do |acceptance|
        "Acceptance #{acceptance.id}: its hash differs from document #{acceptance.document.code}"
      end
    end
  end
end
