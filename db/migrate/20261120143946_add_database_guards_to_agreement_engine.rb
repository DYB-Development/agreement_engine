class AddDatabaseGuardsToAgreementEngine < ActiveRecord::Migration[8.0]
  def up
    execute AgreementEngine::DatabaseGuards::INSTALL if connection.adapter_name.match?(/postg/i)
  end

  def down
    execute AgreementEngine::DatabaseGuards::UNINSTALL if connection.adapter_name.match?(/postg/i)
  end
end
