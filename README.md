# AgreementEngine

Versioned legal document management for Rails. Track and enforce user acceptance of Terms of Service, Privacy Policy, and other legal agreements with versioned documents and audit trails.

## Installation

Add to your Gemfile:

```ruby
gem "agreement_engine"
```

Then run:

```bash
bundle install
rails agreement_engine:install:migrations
rails db:migrate
```

## Setup

### 1. Register document types

Create `config/initializers/agreement_engine.rb`:

```ruby
AgreementEngine.configure do |config|
  config.document_types = [
    AgreementEngine::DocumentType.new(key: :terms_of_service, title: "Terms of Service", kind: :standing, strength: :click_accept, prompts: true),
    AgreementEngine::DocumentType.new(key: :privacy_policy, title: "Privacy Policy", kind: :standing, strength: :click_accept, prompts: true)
  ]
end
```

This list is the one place documents are declared. The sign-in redirect, the
public pages, the admin pages and the seed task all read it. A standing type
that prompts sends signed-in people to accept its current version. Every
standing type has a public page at `/documents/<key>`, and `/terms` and
`/privacy` still serve the terms of service and privacy policy.

### Write and issue documents with keystone_ui-pages

Document content is written in the keystone_ui-pages builder, so the host
installs keystone_ui-pages and runs its migrations before this gem's. The
builder offers a List element, bulleted or numbered, for legal text.

An admin issues a published page version from **Issue a version** on the
documents list, with a version label and an effective date. Issuing keeps a
frozen copy of the page version and records the SHA-256 of its byte form, so
the issued version keeps its text after the page is edited, republished or
deleted. An issued version cannot be edited or deleted.

### 2. Include concerns

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include AgreementEngine::Signable
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include AgreementEngine::Enforceable
end
```

### 3. Mount routes

```ruby
# config/routes.rb
mount AgreementEngine::Engine, at: "/"
```

### 4. Seed initial documents

```bash
rails agreement_engine:seed
```

The seed task issues a starting version for every registered standing type
that has none, from a page you then edit in the builder. A host that registers
keystone_ui-pages places names the place those pages go in:

```ruby
KeystoneUi::Pages.register_place("legal", label: "Legal documents", slug: false)
AgreementEngine.configure { |config| config.pages_place = "legal" }
```

## Acceptance evidence

Every acceptance is kept as its own record, and a record cannot be changed or
deleted. Each one holds the time, the version accepted and its hash, the IP
address, the browser, the statement and button text shown, the
agreement_engine and keystone_ui-pages versions, and a snapshot of the
person's id, name and email as they were at that moment.

A host adds the account, further person details and how the session signed in
through one hook:

```ruby
AgreementEngine.configure do |config|
  config.evidence_method = ->(controller, user) {
    {
      account: {id: controller.current_account.id, name: controller.current_account.name},
      person: {phone: user.phone},
      sign_in: {methods: controller.session_sign_in_methods}
    }
  }
end
```

Host code can ask `user.accepted_current?(:terms_of_service)` and list
`user.accepted_versions(:terms_of_service)`.

Whether a person has accepted is now read from these records, not from the
version columns on the user table, and accepting writes no column. Existing
acceptances in those columns are carried over by the upgrade task, which comes
in a later release.

## Consent to electronic records

A host that asks people to sign turns on the consent type the gem provides:

```ruby
AgreementEngine.configure do |config|
  config.electronic_consent = true
end
```

`rails agreement_engine:seed` then issues version 1.0 from a starting page
covering paper copies, withdrawing consent and what a person needs to open and
keep records. Review that text with your lawyer, edit the page in the builder,
and issue your own versions like any standing document.

A person gives or withdraws consent at `/consent`. A withdrawal is kept beside
the consent it ends, and host code asks `user.holds_consent?`.

## Signatures

A document type whose strength is `:signature` is signed rather than clicked:

```ruby
AgreementEngine::DocumentType.new(key: :statement_of_work, title: "Statement of Work", kind: :standing, strength: :signature)
```

Its signing page is at `/signatures/statement_of_work`. A person without
current consent to electronic records is sent to `/consent` first and brought
back afterwards. The page shows signing wording and asks for the person's typed
full name, and a submission without one is refused. The signature is kept as an
acceptance that also holds the typed name and the consent it relied on.

The signing form carries the hash of the version shown. A submission for a
version that is no longer current is refused and the current version is shown.
A person who withdrew consent is sent back to `/consent`. Submitting the same
form twice records one signature. A page holding an element with no PDF drawing
cannot be issued, and the refusal names the element.

## Documents for one record

A per-record type is filled from a template page with one of the host's
records, such as a quote, a contract or a plan, and accepted or signed in that
exact form.

```ruby
AgreementEngine.configure do |config|
  config.document_types = [
    AgreementEngine::DocumentType.new(key: :plan_sign_off, title: "Plan sign-off", kind: :per_record, strength: :signature, template: "plan-sign-off")
  ]
  config.values_method = ->(record, type) { {client_name: record.client.name} }
  config.may_sign_method = ->(controller, person, document) { document.subject.client.members.include?(person) }
  config.return_check_method = ->(path) { path.start_with?("/plans/") }
end
```

The template is a keystone_ui-pages page whose text is bound to the named
values, and parts of it can be shown or hidden by a value.

```ruby
document = AgreementEngine.issue_for!(:plan_sign_off, plan)
agreement_engine.record_document_path(document, return_to: plan_path(plan))
AgreementEngine.current_for(:plan_sign_off, plan)
AgreementEngine.signers_for(:plan_sign_off, plan)
```

Issuing copies the template's live version and the record's values at that
moment, so a later change to the record changes neither the document nor its
hash. Issuing again for the same record keeps the earlier document and its
acceptances. A person the may-sign check refuses gets a not-found page. The
return address is followed only when it is a path on the host's own site that
the return check allows. Record documents never trigger the accept redirect and
never appear on the public pages.

## Documents that cover a period

A version can cover a period, given when it is issued as a start and end date
or as an ISO 8601 duration counted from acceptance. An admin sets it on the
issue form, and host code passes it to `issue_for!`:

```ruby
AgreementEngine.issue_for!(:service_agreement, contract, period: {"duration" => "P1Y"})
AgreementEngine.in_force(person: user, on: Date.current)
AgreementEngine.in_force(account_id: account.id, on: Date.current)
AgreementEngine.in_force(record: contract, on: Date.current)
```

The period is part of the hash. The accept page, the signing page and the
signer's copy show it. Each acceptance records the dates that apply to it, and
an agreement with no period is in force from its acceptance onward.

## The signer's copy

A person can download a copy of any of their own acceptances:

- `agreement_engine.receipt_path(acceptance, format: :pdf)` is the issued version
  drawn with the values it was issued with, followed by the hash, the time, the
  typed name and the gem versions.
- `agreement_engine.byte_form_receipt_path(acceptance)` is the byte-form file the
  hash was taken from, so `shasum -a 256` on it prints the recorded hash.

A host emails the copy for chosen types:

```ruby
AgreementEngine.configure do |config|
  config.copy_email_types = [:plan_sign_off]
  config.mailer_from = "agreements@example.com"
end
```

The PDF is drawn by keystone_ui-pages, so the host needs Propshaft and a
compiled stylesheet holding the keystone_ui tokens.

## Checking a copy

The rule that turns an issued version into the bytes it is hashed from is
published in `docs/byte-form.md`, with worked examples. Anyone can check a
byte-form file against a hash at `/verify`, which names no signer, or with the
command installed with the gem:

```
agreement_engine-verify copy.json <hash>
```

## Integrity

On PostgreSQL, the gem's migration adds triggers that reject any update or
delete of an acceptance, and of an issued version's frozen copy, hash or
effective date, even when run directly in SQL. Other databases keep the
refusal in the app only.

The admin page marks an issued version whose frozen copy no longer produces its
hash, and one whose page version has since changed or been deleted. Run
`rails agreement_engine:check_hashes` to list every issued version and
acceptance whose hashes disagree. It exits with a failure when it finds one, so
it can run on a schedule.

## Being told about acceptances

A host sets one handler, which is called once each acceptance or signature is
committed:

```ruby
AgreementEngine.configure do |config|
  config.acceptance_handler = ->(event) {
    StartPlanWork.call(event.subject) if event.document_type == :plan_sign_off && event.first_signature?
  }
end
```

The event gives `document_type`, `document`, `person`, `account`, `strength`,
`subject` (the host record of a per-record document) and `first_signature?`.
An error the handler raises is reported through `Rails.error` and never reaches
the person, whose acceptance stays saved. A slow handler slows the accept and
signing pages, so queue long work from inside it.

## Upgrading an app that already uses agreement_engine

An app on 0.1 keeps its documents as Action Text and each user's accepted
version in columns on the user table. The upgrade keeps both and moves them
into the new records.

1. Move to `keystone_ui` 0.49 or later and install `keystone_ui-pages`, with its
   migrations, Active Storage and a Propshaft stylesheet built with the
   keystone_ui tokens.
2. Install this gem's migrations with
   `rails agreement_engine:install:migrations` and run them. They add tables and
   fields and change no existing document, Action Text or user rows.
3. Run `rails "agreement_engine:upgrade[User,terms_accepted_at]"`. The first
   argument is the model that includes `AgreementEngine::Signable`. The second,
   optional, names a column holding when each user accepted. Without it, the
   carried-over acceptances record no time.
4. Read the task's output. It names each version holding content it could not
   carry over, such as tables or images, so those pages can be fixed in the
   builder.

The task makes one page per document type and one published page version per
dated version, holding its headings, paragraphs with links, bold and italic
text, and lists. Each version is then issued in place with its original label
and effective date, frozen and hashed. Each user's stored version becomes one
acceptance marked as carried over, with the person and account as they are at
upgrade time, so nobody is asked to accept again. Running it twice creates
nothing new.

5. Replace `config.agreements` with `config.document_types`, as in Setup
   above. From 0.2 an app that still sets `config.agreements` fails at boot
   with a message naming the replacement. The upgrade task finds each user's
   stored version by the column the 0.1 install created for each type,
   `accepted_<key>_version_id`.
6. Once the task has run and you have checked its result, remove the old
   columns with a migration of your own:

   ```ruby
   class RemoveAgreementEngineVersionColumnsFromUsers < ActiveRecord::Migration[8.0]
     def change
       remove_foreign_key :users, :agreement_engine_documents, column: :accepted_terms_of_service_version_id
       remove_foreign_key :users, :agreement_engine_documents, column: :accepted_privacy_policy_version_id
       remove_column :users, :accepted_terms_of_service_version_id, :bigint
       remove_column :users, :accepted_privacy_policy_version_id, :bigint
     end
   end
   ```

   Generate it with `bin/rails generate migration RemoveAgreementEngineVersionColumnsFromUsers`
   and fill in its body.

What the app gains: editing documents in the page builder, a hash on every
issued version, a kept record of every acceptance with its evidence, consent to
electronic records, signatures, documents for one record and the signer's copy.

### The layout of the gem's pages

The accept, consent, signing, record and verification pages render in the
host's `application` layout, so they load the app's JavaScript and styles.
Before this they rendered in the gem's own minimal layout, which loads neither.
Name another of the app's layouts, or the minimal layout to keep the old look:

```ruby
AgreementEngine.configure do |config|
  config.layout = "agreement_engine/minimal"
end
```

An app that put its own copy of `layouts/agreement_engine/minimal` in its views
to get its layout can delete that copy.

## Auth Configuration

AgreementEngine defaults to Devise conventions. Override for other auth systems:

```ruby
AgreementEngine.configure do |config|
  config.current_user_method = ->(c) { c.current_user }
  config.signed_in_method = ->(c) { c.user_signed_in? }
  config.auth_controller_method = ->(c) { c.devise_controller? }
  config.sign_out_method = ->(c) { c.sign_out(c.current_user) }
end
```

## Routes

The engine provides:

- `GET /agreements/:id` - Show agreement for acceptance
- `PATCH /agreements/:id` - Accept agreement
- `DELETE /agreements/:id` - Decline agreement (signs user out)
- `GET /terms` - Public terms of service page
- `GET /privacy` - Public privacy policy page
- `GET /documents/:document_type` - Public page for any registered standing type
- `GET /admin/documents` - List, view and delete document versions
- `GET /admin/issues/new` - Issue a published page version as a document version
- `GET /consent` - Read the consent to electronic records
- `POST /consent` - Give consent
- `DELETE /consent` - Withdraw consent
- `GET /signatures/:document_type` - Signing page for a signature-strength type
- `PATCH /signatures/:document_type` - Sign it
- `GET /verify` - Check a byte-form file against a hash
- `GET /receipts/:id.pdf` - A person's PDF copy of their acceptance
- `GET /receipts/:id/byte_form` - The byte-form file its hash was taken from
- `GET /records/:code` - Accept or sign one record's document
- `PATCH /records/:code` - Accept or sign it

## Development

```bash
bundle install
bundle exec rake test
```
