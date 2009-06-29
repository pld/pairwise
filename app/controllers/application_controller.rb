class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  if LOG_DETAIL
    include Oink::MemoryUsageLogger
    include Oink::InstanceTypeCounter
  end

  helper :all # include all helpers, all the time

  prepend_before_filter :login_required

  protect_from_forgery

  # purge "password" from logs
  filter_parameter_logging :password

  # rescue errors and return HTTP status codes
  rescue_from 'PermissionError' do |e| http_status_code(:forbidden, e) end
  rescue_from 'ArgumentError' do |e| http_status_code(:expectation_failed, e) end
  rescue_from ActiveRecord::RecordNotFound do |e| http_status_code(:bad_request, e) end
  rescue_from ActiveRecord::RecordInvalid do |e| http_status_code(:bad_request, e) end
  rescue_from LibXML::XML::Error do |e| http_status_code(:bad_request, e) end
  rescue_from REXML::ParseException do |e| http_status_code(:bad_request, e) end

  if ENV['RAILS_ENV'] == 'production'
    rescue_from Exception do |e| notify_and_handle(e) end
  end

  def http_status_code(status, exception)
    respond_to do |format|
      format.any { head status }
    end
  end

  def force_xml
    params.merge!(:format => :xml) unless params.include?(:format)
  end

  def admin_required
    redirect_back_or_default('/') unless current_user && current_user.admin?
  end

  protected
    def parse_model_name(model, str)
      id = str.to_i
      if id == 0 && !(str.nil? || str.blank?)
        rec = model.first(:conditions => { :name => str })
        id = rec.id if rec
      end
      id
    end

  private
    def notify_and_handle(e)
      @requested_page= e.to_s
      if e.class == ActionController::RoutingError || e.class == ActionController::UnknownAction
        @error = "File or location does not exist."
        render :template => '/home/error'
      else
        SystemNotifier.deliver_exception(self, request, current_visit, e)
        flash.now[:error] = "We encountered an internal error. We have been notified and are working to fix the problem."
        render :template => '/home/index'
      end
    end
end
