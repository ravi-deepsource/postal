require 'authie/session'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :login_required
  before_action :verified_email_required
  before_action :set_timezone

  rescue_from Authie::Session::InactiveSession, with: :auth_session_error
  rescue_from Authie::Session::ExpiredSession, with: :auth_session_error
  rescue_from Authie::Session::BrowserMismatch, with: :auth_session_error

  private

  def login_required
    redirect_to login_path(return_to: request.fullpath) unless logged_in?
  end

  def admin_required
    if logged_in?
      render text: 'Not permitted' unless current_user.admin?
    else
      redirect_to login_path(return_to: request.fullpath)
    end
  end

  def verified_email_required
    redirect_to verify_path(return_to: request.fullpath) if logged_in? && !current_user.verified?
  end

  def require_organization_admin
    unless organization.admin?(current_user)
      redirect_to organization_root_path(organization), alert: 'This page can only be accessed by the organization admins'
    end
  end

  def require_organization_owner
    unless organization.owner == current_user
      redirect_to organization_root_path(organization), alert: "This page can only be accessed by the organization's owner (#{organization.owner.name})"
    end
  end

  def auth_session_error(exception)
    Rails.logger.info "AuthSessionError: #{exception.class}: #{exception.message}"
    redirect_to login_path(return_to: request.fullpath)
  end

  def page_title
    @page_title ||= ['Postal']
  end
  helper_method :page_title

  def redirect_to_with_return_to(url, *args)
    if params[:return_to].blank? || !params[:return_to].starts_with?('/')
      redirect_to url_with_return_to(url), *args
    else
      redirect_to url_with_return_to(url), *args
    end
  end

  def set_timezone
    Time.zone = logged_in? ? current_user.time_zone : 'UTC'
  end

  def append_info_to_payload(payload)
    super
    payload[:ip] = request.ip
    payload[:user] = logged_in? ? current_user.id : nil
  end

  def url_with_return_to(url)
    if params[:return_to].blank? || !params[:return_to].starts_with?('/')
      url_for(url)
    else
      params[:return_to]
    end
  end

  def redirect_to_with_json(url, flash_messages = {})
    url = if url.is_a?(Array) && url[0] == :return_to
            url_with_return_to(url[1])
          else
            url_for(url)
          end

    flash_messages.each do |key, value|
      flash[key] = value
    end
    respond_to do |wants|
      wants.html { redirect_to url }
      wants.json { render json: { redirect_to: url } }
    end
  end

  def render_form_errors(action_name, object)
    respond_to do |wants|
      wants.html { render action_name }
      wants.json { render json: { form_errors: object.errors.full_messages }, status: 422 }
    end
  end

  def flash_now(type, message, options = {})
    respond_to do |wants|
      wants.html do
        flash.now[type] = message
        render options[:render_action] if options[:render_action]
      end
      wants.json { render json: { flash: { type => message } } }
    end
  end

  def login(user)
    if logged_in?
      auth_session.invalidate!
      reset_session
    end
    Authie::Session.start(self, user: user)
    @current_user = user
  end
end
