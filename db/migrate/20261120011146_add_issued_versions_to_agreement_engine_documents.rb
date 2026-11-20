class AddIssuedVersionsToAgreementEngineDocuments < ActiveRecord::Migration[8.0]
  def change
    add_reference :agreement_engine_documents, :page_version, foreign_key: {to_table: :keystone_ui_pages_versions, on_delete: :nullify}
    add_column :agreement_engine_documents, :frozen_copy, :json
    add_column :agreement_engine_documents, :content_hash, :string
    add_column :agreement_engine_documents, :byte_form_version, :integer
  end
end
