class AddOneSignatureIndexToAgreementEngineAcceptances < ActiveRecord::Migration[8.0]
  def change
    add_index :agreement_engine_acceptances, [:signer_type, :signer_id, :document_id], unique: true, where: "strength = 'signature'", name: "index_agreement_engine_acceptances_one_signature"
  end
end
