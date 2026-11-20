class AddPeriodToAgreementEngineAcceptances < ActiveRecord::Migration[8.0]
  def change
    add_column :agreement_engine_acceptances, :period_starts_on, :date
    add_column :agreement_engine_acceptances, :period_ends_on, :date
  end
end
