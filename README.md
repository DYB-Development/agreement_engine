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

### 1. Configure agreements

Create `config/initializers/agreement_engine.rb`:

```ruby
AgreementEngine.configure do |config|
  config.agreements = [
    AgreementEngine::Agreement.new(
      id: :terms_of_service,
      title: "Terms Of Service",
      version_column: :accepted_terms_of_service_version_id,
      document_type: :terms_of_service,
      prompt_when_updated: true
    ),
    AgreementEngine::Agreement.new(
      id: :privacy_policy,
      title: "Privacy Policy",
      version_column: :accepted_privacy_policy_version_id,
      document_type: :privacy_policy,
      prompt_when_updated: true
    )
  ]
end
```

### Register document types

A host can register document types of its own beside the agreements above.
Each agreement listed the existing way is also available as a registered type.

```ruby
AgreementEngine.configure do |config|
  config.document_types = [
    AgreementEngine::DocumentType.new(key: :nda, title: "Mutual NDA", kind: :standing, strength: :click_accept)
  ]
end
```

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
- `GET /admin/documents` - Admin CRUD for managing document versions
- `GET /admin/issues/new` - Issue a published page version as a document version

## Development

```bash
bundle install
bundle exec rake test
```
