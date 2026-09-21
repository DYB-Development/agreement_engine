ActiveRecord::Schema[8.0].define(version: 1) do
  create_table :agreement_engine_documents do |t|
    t.string :document_type, null: false
    t.string :version, null: false
    t.datetime :effective_at
    t.text :summary

    t.timestamps
  end

  add_index :agreement_engine_documents, [:document_type, :version], unique: true
  add_index :agreement_engine_documents, [:document_type, :effective_at]

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
