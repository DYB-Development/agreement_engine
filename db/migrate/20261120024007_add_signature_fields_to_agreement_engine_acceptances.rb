class AddSignatureFieldsToAgreementEngineAcceptances < ActiveRecord::Migration[8.0]
  def change
    add_column :agreement_engine_acceptances, :strength, :string, null: false, default: "click_accept"
    add_column :agreement_engine_acceptances, :typed_name, :string
    add_reference :agreement_engine_acceptances, :consent, foreign_key: {to_table: :agreement_engine_acceptances}
  end
end
