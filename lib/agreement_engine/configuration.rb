# frozen_string_literal: true

module AgreementEngine
  class Configuration
    attr_accessor :document_types
    attr_accessor :current_user_method
    attr_accessor :signed_in_method
    attr_accessor :auth_controller_method
    attr_accessor :sign_out_method
    attr_accessor :admin_auth_method
    attr_accessor :evidence_method
    attr_accessor :electronic_consent
    attr_accessor :values_method
    attr_accessor :may_sign_method
    attr_accessor :return_check_method
    attr_accessor :acceptance_handler
    attr_accessor :copy_email_types
    attr_accessor :mailer_from
    attr_accessor :pages_place
    attr_accessor :layout

    def initialize
      @document_types = []
      @copy_email_types = []
      @layout = "application"

      @current_user_method = ->(c) { c.current_user }
      @signed_in_method = ->(c) { c.user_signed_in? }
      @auth_controller_method = ->(c) { c.respond_to?(:devise_controller?) && c.devise_controller? }
      @sign_out_method = ->(c) {
        if defined?(Devise) && Devise.sign_out_all_scopes
          c.sign_out
        else
          c.sign_out(c.current_user)
        end
      }
      @admin_auth_method = ->(c) {
        c.redirect_to("/", alert: "Not authorized") unless signed_in?(c)
      }
    end

    def agreements=(_list)
      raise ArgumentError, "config.agreements was replaced by config.document_types in agreement_engine 0.2. Register each agreement as AgreementEngine::DocumentType.new(key:, title:, kind: :standing, strength: :click_accept, prompts: true)."
    end

    def registered_document_types
      document_types + (electronic_consent ? [Consent::TYPE] : [])
    end

    def evidence(controller, signer)
      (evidence_method&.call(controller, signer) || {}).to_h.transform_keys(&:to_sym)
    end

    def allowed_return_path(path)
      path = path.to_s
      return unless path.start_with?("/") && !path.start_with?("//") && !path.include?("\\")
      return if return_check_method && return_check_method.call(path) != true

      path
    end

    def may_sign?(controller, person, document)
      may_sign_method.present? && may_sign_method.call(controller, person, document) == true
    end

    def current_user(controller) = current_user_method.call(controller)
    def signed_in?(controller) = signed_in_method.call(controller)
    def auth_controller?(controller) = auth_controller_method.call(controller)
    def sign_out(controller) = sign_out_method.call(controller)
    def authenticate_admin!(controller) = admin_auth_method.call(controller)
  end
end
