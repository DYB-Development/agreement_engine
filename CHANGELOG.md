# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-11-23

### Added

- A document type takes `reading:` with `seconds:`, `scroll: true` or `open: true`, and the accept, signing and record pages refuse an acceptance or signature sent before the minimum time has passed since the page was first shown (#57, #64)
- The accept, signing and record pages hold their button with keystone_ui's reading hold, showing the seconds left and waiting for the end of the document when scrolling is required (#62, #63, #64)
- Each acceptance and signature keeps its reading evidence: the minimum time and the seconds the server measured, the browser's report of reaching the end, and where and when the document was opened (#57, #59, #63, #64)
- Host code asks `agreement_engine_opened(:type)` whether the session opened a document's public page, and `accept_version!` takes the answer as `reading:` (#59)
- The signer's copy lists the reading evidence, and the acceptance event exposes it as `reading` (#66)
- `config.layout` names the layout the accept, consent, signing, record and verification pages render in (#58)

### Changed

- The gem's accept, consent, signing, record and verification pages render in the host's `application` layout by default; name `"agreement_engine/minimal"` to keep the old look (#58)
- The accept, signing, record and consent pages are drawn with keystone_ui components, and a refused signature keeps its typed name (#62, #64)
- agreement_engine depends on keystone_ui 0.106.0 or later (#62)
- A mistyped reading requirement stops the app at boot, and host code accepting a type that requires opening without an opening of that version raises (#60, #61)

### Fixed

- An acceptance refused on the accept page now counts the time spent on the page shown with the refusal toward the minimum reading time (#68)

## [0.2.2] - 2026-11-20

### Added

- `config.pages_place` names the keystone_ui-pages place the seed task and the upgrade create their pages in, for hosts that register places

## [0.2.1] - 2026-11-20

### Fixed

- Installing the engine no longer adds the host app's route helpers to every controller, which made other engines' links point at the host app's routes

## [0.2.0] - 2026-11-20

### Added

- Registered document types with a key, title, kind and strength, read alongside the listed agreements
- Issuing a published keystone_ui-pages page version as a document version, with a frozen copy and a SHA-256 hash of its byte form
- Issued versions refuse edits and deletion
- A List element, bulleted or numbered, in the keystone_ui-pages builder
- A runtime dependency on keystone_ui-pages
- Acceptance records that keep the evidence of each acceptance and cannot be changed or deleted
- An evidence hook through which a host supplies the account, further person details and how the session signed in
- `accepted_current?` and `accepted_versions` on the signer
- Signing refuses a version that is no longer current, records one signature per person per version, and keeps the signature when its copy cannot be drawn or emailed
- Issuing refuses a page holding an element with no PDF drawing
- PostgreSQL triggers that reject changes to acceptances and issued versions, admin marks for broken or moved versions, and `agreement_engine:check_hashes`
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
