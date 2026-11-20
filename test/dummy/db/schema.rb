ActiveRecord::Schema[8.0].define(version: 1) do
  create_table :keystone_ui_pages_pages do |t|
    t.string :name, null: false
    t.string :slug, null: false
    t.json :document, null: false
    t.references :owner, polymorphic: true
    t.json :undo_history
    t.json :undone_changes
    t.string :place
    t.string :access_exception
    t.datetime :archived_at
    t.string :sequence_key

    t.timestamps
  end

  create_table :keystone_ui_pages_versions do |t|
    t.references :page, null: false
    t.integer :number, null: false
    t.json :document, null: false
    t.string :status, null: false

    t.timestamps
  end

  create_table :agreement_engine_documents do |t|
    t.string :document_type, null: false
    t.string :version, null: false
    t.datetime :effective_at
    t.text :summary
    t.references :page_version
    t.json :frozen_copy
    t.string :content_hash
    t.integer :byte_form_version
    t.references :subject, polymorphic: true
    t.string :code

    t.timestamps
  end

  add_index :agreement_engine_documents, :code, unique: true
  add_index :agreement_engine_documents, [:document_type, :subject_type, :subject_id, :version], unique: true, name: "index_agreement_engine_documents_on_type_subject_and_version"
  add_index :agreement_engine_documents, [:document_type, :effective_at]

  create_table :agreement_engine_acceptances do |t|
    t.references :signer, polymorphic: true, null: false
    t.references :document, null: false
    t.string :content_hash
    t.integer :byte_form_version
    t.datetime :accepted_at
    t.string :ip_address
    t.text :user_agent
    t.text :statement
    t.string :button_text
    t.json :person
    t.json :account
    t.json :sign_in
    t.string :engine_version
    t.string :pages_version
    t.string :strength, null: false, default: "click_accept"
    t.string :typed_name
    t.references :consent
    t.boolean :carried_over, null: false, default: false
    t.boolean :time_reported_by_host, null: false, default: false
    t.datetime :snapshot_taken_at
    t.date :period_starts_on
    t.date :period_ends_on

    t.timestamps
  end

  add_index :agreement_engine_acceptances, [:signer_type, :signer_id, :document_id], unique: true, where: "strength = 'signature'", name: "index_agreement_engine_acceptances_one_signature"

  create_table :agreement_engine_consent_withdrawals do |t|
    t.references :acceptance, null: false, index: {unique: true}
    t.datetime :withdrawn_at, null: false
    t.string :ip_address
    t.text :user_agent

    t.timestamps
  end

  create_table :action_text_rich_texts do |t|
    t.string :name, null: false
    t.text :body
    t.references :record, null: false, polymorphic: true, index: false

    t.timestamps

    t.index [:record_type, :record_id, :name], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table :active_storage_blobs do |t|
    t.string :key, null: false
    t.string :filename, null: false
    t.string :content_type
    t.text :metadata
    t.string :service_name, null: false
    t.bigint :byte_size, null: false
    t.string :checksum

    t.timestamps

    t.index [:key], unique: true
  end

  create_table :active_storage_attachments do |t|
    t.string :name, null: false
    t.references :record, null: false, polymorphic: true, index: false
    t.references :blob, null: false

    t.timestamps

    t.index [:record_type, :record_id, :name, :blob_id], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table :active_storage_variant_records do |t|
    t.belongs_to :blob, null: false, index: false
    t.string :variation_digest, null: false

    t.index [:blob_id, :variation_digest], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table :users do |t|
    t.string :name
    t.string :email
    t.boolean :admin, default: false, null: false
    t.bigint :accepted_terms_of_service_version_id
    t.bigint :accepted_privacy_policy_version_id

    t.timestamps
  end

  add_foreign_key :users, :agreement_engine_documents, column: :accepted_terms_of_service_version_id
  add_foreign_key :users, :agreement_engine_documents, column: :accepted_privacy_policy_version_id
end
