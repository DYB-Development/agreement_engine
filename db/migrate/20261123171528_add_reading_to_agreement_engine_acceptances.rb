class AddReadingToAgreementEngineAcceptances < ActiveRecord::Migration[8.0]
  def change
    add_column :agreement_engine_acceptances, :reading, :json
  end
end
