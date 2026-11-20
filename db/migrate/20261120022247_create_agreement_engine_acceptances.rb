class CreateAgreementEngineAcceptances < ActiveRecord::Migration[8.0]
  def change
    create_table :agreement_engine_acceptances do |t|
      t.references :signer, polymorphic: true, null: false
      t.references :document, null: false, foreign_key: {to_table: :agreement_engine_documents}
      t.string :content_hash
      t.integer :byte_form_version
      t.datetime :accepted_at, null: false
      t.string :ip_address
      t.text :user_agent
      t.text :statement
      t.string :button_text
      t.json :person
      t.json :account
      t.json :sign_in
      t.string :engine_version
      t.string :pages_version

      t.timestamps
    end
  end
end
