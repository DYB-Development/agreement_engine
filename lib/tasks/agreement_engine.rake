namespace :agreement_engine do
  desc "Issue a starting version for every registered standing document type that has none"
  task seed: :environment do
    puts "Seeding legal documents..."
    AgreementEngine::Seed.run.compact.each { |document| puts "  Issued #{document.document_type.titleize} v#{document.version}" }
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
