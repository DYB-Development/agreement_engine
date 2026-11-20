# frozen_string_literal: true

module AgreementEngine
  class ConsentWithdrawal < ActiveRecord::Base
    self.table_name = "agreement_engine_consent_withdrawals"

    belongs_to :acceptance, class_name: "AgreementEngine::Acceptance"

    def readonly?
      persisted?
    end
  end
end
