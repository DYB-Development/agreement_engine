class ApplicationController < ActionController::Base
  include AgreementEngine::Enforceable

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  helper_method :current_user

  def store_location_for(_scope, path)
    session[:return_to] = path
  end

  def stored_location_for(_scope)
    session.delete(:return_to)
  end
end
