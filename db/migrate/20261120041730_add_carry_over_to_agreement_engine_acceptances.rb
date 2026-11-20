class AddCarryOverToAgreementEngineAcceptances < ActiveRecord::Migration[8.0]
  def change
    change_column_null :agreement_engine_acceptances, :accepted_at, true
    add_column :agreement_engine_acceptances, :carried_over, :boolean, null: false, default: false
    add_column :agreement_engine_acceptances, :time_reported_by_host, :boolean, null: false, default: false
    add_column :agreement_engine_acceptances, :snapshot_taken_at, :datetime
  end
end
