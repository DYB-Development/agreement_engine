AgreementEngine.configure do |config|
  # Lambda called to get the current user (default: controller.current_user)
  # config.current_user_method = ->(controller) { controller.current_user }

  # Lambda called to check if a user is signed in (default: controller.user_signed_in?)
  # config.signed_in_method = ->(controller) { controller.user_signed_in? }

  # Lambda called to authorize admin access (default: redirects if not signed in)
  # config.admin_auth_method = ->(controller) {
  #   controller.redirect_to("/", alert: "Not authorized") unless config.signed_in?(controller)
  # }

  # Register your documents. A standing type that prompts sends signed-in people
  # to accept its current version:
  # config.document_types = [
  #   AgreementEngine::DocumentType.new(key: :terms_of_service, title: "Terms of Service", kind: :standing, strength: :click_accept, prompts: true),
  #   AgreementEngine::DocumentType.new(key: :privacy_policy, title: "Privacy Policy", kind: :standing, strength: :click_accept, prompts: true)
  # ]
end
