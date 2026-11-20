class AddSubjectToAgreementEngineDocuments < ActiveRecord::Migration[8.0]
  def change
    add_reference :agreement_engine_documents, :subject, polymorphic: true
    add_column :agreement_engine_documents, :code, :string
    add_index :agreement_engine_documents, :code, unique: true
    remove_index :agreement_engine_documents, [:document_type, :version], unique: true
    add_index :agreement_engine_documents, [:document_type, :subject_type, :subject_id, :version], unique: true, name: "index_agreement_engine_documents_on_type_subject_and_version"
  end
end
