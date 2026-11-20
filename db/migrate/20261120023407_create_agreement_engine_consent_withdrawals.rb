class CreateAgreementEngineConsentWithdrawals < ActiveRecord::Migration[8.0]
  def change
    create_table :agreement_engine_consent_withdrawals do |t|
      t.references :acceptance, null: false, index: {unique: true}, foreign_key: {to_table: :agreement_engine_acceptances}
      t.datetime :withdrawn_at, null: false
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end
  end
end
