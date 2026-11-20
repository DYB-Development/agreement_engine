namespace :agreement_engine do
  desc "Seed initial legal document versions for each configured agreement"
  task seed: :environment do
    puts "Seeding legal documents..."

    AgreementEngine.config.agreements.each do |agreement|
      if AgreementEngine::Document.where(document_type: agreement.document_type).exists?
        puts "  #{agreement.title} v1.0 already exists, skipping"
      else
        AgreementEngine::Document.create!(
          document_type: agreement.document_type,
          version: "1.0",
          summary: "Initial #{agreement.title.downcase}",
          content: "<h2>#{agreement.title}</h2><p>This is a placeholder. Please update with your actual #{agreement.title.downcase}.</p>",
          effective_at: Time.current
        )
        puts "  Created #{agreement.title} v1.0"
      end
    end

    if AgreementEngine.config.electronic_consent
      if AgreementEngine::Consent.seed!
        puts "  Issued Consent to Electronic Records v1.0"
      else
        puts "  Consent to Electronic Records already exists, skipping"
      end
    end

    puts "Done!"
  end

  desc "Move legacy documents into pages and carry over each user's stored acceptances, as agreement_engine:upgrade[User,terms_accepted_at]"
  task :upgrade, [:signer_class, :time_column] => :environment do |_task, args|
    report = AgreementEngine::Upgrade.run(signer_class: (args[:signer_class] || "User").constantize, time_column: args[:time_column].presence&.to_sym)
    report.left_out.each do |document_type, version, tags|
      puts "  #{document_type} #{version} could not carry over: #{tags.join(", ")}"
    end
    puts "Upgrade done."
  end
end
