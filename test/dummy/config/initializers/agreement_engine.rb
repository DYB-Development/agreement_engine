AgreementEngine.configure do |config|
  config.agreements = [
    AgreementEngine::Agreement.new(
      id: :terms_of_service,
      title: "Terms Of Service",
      version_column: :accepted_terms_of_service_version_id,
      document_type: :terms_of_service,
      prompt_when_updated: true
    ),
    AgreementEngine::Agreement.new(
      id: :privacy_policy,
      title: "Privacy Policy",
      version_column: :accepted_privacy_policy_version_id,
      document_type: :privacy_policy,
      prompt_when_updated: true
    )
  ]

  config.current_user_method = ->(c) { c.current_user }
  config.signed_in_method = ->(c) { c.current_user.present? }
  config.auth_controller_method = ->(_c) { false }
  config.sign_out_method = ->(c) { c.session.delete(:user_id) }
  config.admin_auth_method = ->(c) {
    user = c.current_user
    unless user&.admin?
      c.redirect_to "/", alert: "Not authorized"
    end
  }
end
