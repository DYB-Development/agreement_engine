AgreementEngine.configure do |config|
  # Lambda called to get the current user (default: controller.current_user)
  # config.current_user_method = ->(controller) { controller.current_user }

  # Lambda called to check if a user is signed in (default: controller.user_signed_in?)
  # config.signed_in_method = ->(controller) { controller.user_signed_in? }

  # Lambda called to authorize admin access (default: redirects if not signed in)
  # config.admin_auth_method = ->(controller) {
  #   controller.redirect_to("/", alert: "Not authorized") unless config.signed_in?(controller)
  # }

  # Define your legal agreements:
  # config.agreements = [
  #   AgreementEngine::Agreement.new(:terms, title: "Terms of Service", required: true),
  #   AgreementEngine::Agreement.new(:privacy, title: "Privacy Policy", required: true),
  # ]
end
