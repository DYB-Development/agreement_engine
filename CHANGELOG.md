# Changelog

All notable changes to this project will be documented in this file.

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
