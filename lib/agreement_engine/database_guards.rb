# frozen_string_literal: true

module AgreementEngine
  module DatabaseGuards
    INSTALL = <<~SQL
      CREATE OR REPLACE FUNCTION agreement_engine_refuse_acceptance_change() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'agreement_engine acceptances cannot be changed or deleted';
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION agreement_engine_refuse_issued_change() RETURNS trigger AS $$
      BEGIN
        IF OLD.content_hash IS NULL THEN
          IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
          RETURN NEW;
        END IF;
        IF TG_OP = 'DELETE' THEN
          RAISE EXCEPTION 'agreement_engine issued versions cannot be deleted';
        END IF;
        IF NEW.frozen_copy::text IS DISTINCT FROM OLD.frozen_copy::text
          OR NEW.content_hash IS DISTINCT FROM OLD.content_hash
          OR NEW.effective_at IS DISTINCT FROM OLD.effective_at THEN
          RAISE EXCEPTION 'agreement_engine issued versions cannot be changed';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      DROP TRIGGER IF EXISTS agreement_engine_acceptances_frozen ON agreement_engine_acceptances;
      CREATE TRIGGER agreement_engine_acceptances_frozen BEFORE UPDATE OR DELETE ON agreement_engine_acceptances
        FOR EACH ROW EXECUTE FUNCTION agreement_engine_refuse_acceptance_change();

      DROP TRIGGER IF EXISTS agreement_engine_documents_frozen ON agreement_engine_documents;
      CREATE TRIGGER agreement_engine_documents_frozen BEFORE UPDATE OR DELETE ON agreement_engine_documents
        FOR EACH ROW EXECUTE FUNCTION agreement_engine_refuse_issued_change();
    SQL

    UNINSTALL = <<~SQL
      DROP TRIGGER IF EXISTS agreement_engine_acceptances_frozen ON agreement_engine_acceptances;
      DROP TRIGGER IF EXISTS agreement_engine_documents_frozen ON agreement_engine_documents;
      DROP FUNCTION IF EXISTS agreement_engine_refuse_acceptance_change();
      DROP FUNCTION IF EXISTS agreement_engine_refuse_issued_change();
    SQL
  end
end
