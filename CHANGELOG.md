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

### Changed

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
