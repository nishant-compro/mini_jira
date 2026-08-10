class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  skip_forgery_protection if: -> { request.format.json? }

  helper_method :current_user

  def current_user
    @current_user ||= User.find_by(id: session[:current_user_id])
  end
end
