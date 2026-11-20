Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :rescuable
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecations_treatment = :raise
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.delivery_method = :test
  config.active_job.queue_adapter = :test
end
