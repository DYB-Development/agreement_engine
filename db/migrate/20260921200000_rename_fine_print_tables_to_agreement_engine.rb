class RenameFinePrintTablesToAgreementEngine < ActiveRecord::Migration[8.0]
  def change
    rename_table :fine_print_documents, :agreement_engine_documents
  end
end
