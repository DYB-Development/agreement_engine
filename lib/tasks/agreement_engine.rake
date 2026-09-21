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

    puts "Done!"
  end
end
