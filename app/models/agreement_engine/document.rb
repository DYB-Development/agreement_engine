# frozen_string_literal: true

module AgreementEngine
  class Document < ActiveRecord::Base
    self.table_name = "agreement_engine_documents"

    has_rich_text :content

    validates :document_type, presence: true
    validates :version, presence: true, uniqueness: {scope: [:document_type, :subject_type, :subject_id]}
    validates :content, presence: true, unless: :content_hash

    scope :published, -> { where("effective_at <= ?", Time.current) }
    scope :draft, -> { where(effective_at: nil) }

    FROZEN = "Issued versions are frozen and cannot be changed or deleted."

    before_destroy :refuse_when_issued
    validate :unchanged_once_issued, on: :update

    has_many :acceptances, -> { order(:accepted_at, :id) }, class_name: "AgreementEngine::Acceptance"

    belongs_to :page_version, class_name: "KeystoneUi::Pages::Version", optional: true
    belongs_to :subject, polymorphic: true, optional: true

    before_create { self.code ||= SecureRandom.alphanumeric(20) }

    def to_param = code

    def self.issue!(type:, page_version:, version:, effective_at:, subject: nil, values: {})
      frozen_copy = {"slug" => page_version.page.slug, "number" => page_version.number, "document" => page_version.document, "values" => values}
      create!(
        subject: subject,
        document_type: type.to_s,
        version: version,
        effective_at: effective_at,
        page_version: page_version,
        frozen_copy: frozen_copy,
        byte_form_version: ByteForm::VERSION,
        content_hash: ByteForm.digest(slug: frozen_copy["slug"], number: frozen_copy["number"], document: frozen_copy["document"], values: values)
      )
    end

    def issue_in_place!(page_version)
      copy = {"slug" => page_version.page.slug, "number" => page_version.number, "document" => page_version.document, "values" => {}}
      update!(
        page_version: page_version,
        frozen_copy: copy,
        byte_form_version: ByteForm::VERSION,
        content_hash: ByteForm.digest(slug: copy["slug"], number: copy["number"], document: copy["document"])
      )
    end

    def self.current(document_type)
      where(document_type: document_type, subject_id: nil)
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

    def unchanged_once_issued
      errors.add(:base, FROZEN) if content_hash_was.present? && changed?
    end

    def refuse_when_issued
      return unless issued?

      errors.add(:base, FROZEN)
      throw :abort
    end
  end
end
