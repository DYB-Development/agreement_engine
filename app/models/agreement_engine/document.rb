# frozen_string_literal: true

module AgreementEngine
  class Document < ActiveRecord::Base
    self.table_name = "agreement_engine_documents"

    has_rich_text :content

    validates :document_type, presence: true
    validates :version, presence: true, uniqueness: {scope: :document_type}
    validates :content, presence: true, unless: :content_hash

    scope :published, -> { where("effective_at <= ?", Time.current) }
    scope :draft, -> { where(effective_at: nil) }

    FROZEN = "Issued versions are frozen and cannot be changed or deleted."

    before_destroy :refuse_when_issued

    belongs_to :page_version, class_name: "KeystoneUi::Pages::Version", optional: true

    def self.issue!(type:, page_version:, version:, effective_at:)
      frozen_copy = {"slug" => page_version.page.slug, "number" => page_version.number, "document" => page_version.document, "values" => {}}
      create!(
        document_type: type.to_s,
        version: version,
        effective_at: effective_at,
        page_version: page_version,
        frozen_copy: frozen_copy,
        byte_form_version: ByteForm::VERSION,
        content_hash: ByteForm.digest(slug: frozen_copy["slug"], number: frozen_copy["number"], document: frozen_copy["document"])
      )
    end

    def self.current(document_type)
      where(document_type: document_type)
        .published
        .order(effective_at: :desc)
        .first
    end

    def issued?
      content_hash.present?
    end

    def published?
      effective_at.present? && effective_at <= Time.current
    end

    private

    def refuse_when_issued
      return unless issued?

      errors.add(:base, FROZEN)
      throw :abort
    end
  end
end
