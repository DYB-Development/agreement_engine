# frozen_string_literal: true

module AgreementEngine
  class Document < ActiveRecord::Base
    self.table_name = "agreement_engine_documents"

    has_rich_text :content

    validates :document_type, presence: true
    validates :version, presence: true, uniqueness: {scope: :document_type}
    validates :content, presence: true

    scope :published, -> { where("effective_at <= ?", Time.current) }
    scope :draft, -> { where(effective_at: nil) }

    def self.current(document_type)
      where(document_type: document_type)
        .published
        .order(effective_at: :desc)
        .first
    end

    def published?
      effective_at.present? && effective_at <= Time.current
    end
  end
end
