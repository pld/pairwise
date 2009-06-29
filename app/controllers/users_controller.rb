class UsersController < ApplicationController  
  skip_before_filter :login_required
  before_filter :admin_required, :only => [:index, :suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :force_xml, :only => :add

  def index
    @users = User.find(:all)
  end

  # render new.rhtml
  def new
    @user = User.new
  end

  # Create user account but do not give out activation code.
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      # UserMailer.deliver_signup_notification(@user)
      UserMailer.deliver_admin_notification(@user)
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We'll send an email upon account activation."
    else
      @user.password = @user.password_confirmation = nil
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def add
    return unless request.post? && params[:key] && Base64.decode64(params[:key]) == Constants::USER_KEY
    xml = LibXML::XML::Parser.parse(request.raw_post)
    password = Base64.decode64(xml.find("/user/password").first.content)
    @user = User.new(:login => xml.find("/user/login").first.content,
      :email => xml.find("/user/email").first.content,
      :password => password, :password_confirmation => password)
    @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      @user.activate!
      UserMailer.deliver_admin_notification(@user)
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:id]) unless params[:id].blank?
    case
    when (!params[:id].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:id].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end

  def suspend
    @user.suspend!
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend!
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end

  protected
    def find_user
      @user = User.find(params[:id])
    end
end