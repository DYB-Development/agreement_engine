AgreementEngine.configure do |config|
  config.document_types = [
    AgreementEngine::DocumentType.new(key: :terms_of_service, title: "Terms Of Service", kind: :standing, strength: :click_accept, prompts: true),
    AgreementEngine::DocumentType.new(key: :privacy_policy, title: "Privacy Policy", kind: :standing, strength: :click_accept, prompts: true)
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
