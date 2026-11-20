# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Registered document types with a key, title, kind and strength, read alongside the listed agreements
- Issuing a published keystone_ui-pages page version as a document version, with a frozen copy and a SHA-256 hash of its byte form
- Issued versions refuse edits and deletion
- A List element, bulleted or numbered, in the keystone_ui-pages builder
- A runtime dependency on keystone_ui-pages
- Acceptance records that keep the evidence of each acceptance and cannot be changed or deleted
- An evidence hook through which a host supplies the account, further person details and how the session signed in
- `accepted_current?` and `accepted_versions` on the signer
- Periods on documents, recorded on each acceptance, with `AgreementEngine.in_force`
- A verify page and an `agreement_engine-verify` command, and the published byte-form rule with worked examples
- An upgrade task that moves Action Text documents into page versions and carries over each user's stored acceptance
- The signer's copy: a PDF with an evidence summary, the byte-form file, and an email for chosen types
- A PDF drawing for the List element
- A host handler told about each acceptance and signature once committed, including the first signature on a record's document
- Per-record documents filled from a template page with one host record's values, with a may-sign check, a return address and `issue_for!`, `current_for` and `signers_for`
- Documents are addressed by a random code in place of their database id
- Signature-strength document types with a signing page, a typed name, and consent required first
- A consent to electronic records type a host can enable, with a starting page, a consent page, withdrawal records and `holds_consent?`

### Changed

- Every page draws an issued version from its frozen copy through one partial, which fixes the accept page showing the old rich text

- `config.document_types` is the one place documents are declared, and setting `config.agreements` now fails at boot
- Every registered standing type has a public page, and the seed task issues a starting version for each
- The admin pages no longer offer the rich-text editor; versions are issued from published pages

- Whether a person has accepted is read from acceptance records, and accepting no longer writes the user's version columns

## [0.1.0] - 2026-02-12

### Added

- Rails engine with isolated namespace
- `AgreementEngine::Document` model with versioned legal document management
- `Signable` concern for user models to track agreement acceptance
- `Enforceable` concern for controllers to require agreement acceptance
- `AgreementsController` for user-facing acceptance flow
- `DocumentsController` with public terms and privacy pages
- `Admin::DocumentsController` with full CRUD and auth protection
- Engine migrations for documents table and user tracking columns
- Seed rake task (`agreement_engine:seed`) for initial legal documents
- Host app route helpers exposed to engine views
- GitHub Actions CI workflow
