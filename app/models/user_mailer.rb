class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "#{Constants::BASE_URL}activate/#{user.activation_code}"
  end

  def admin_notification(user)
    setup_email(user)
    @recipients = Constants::ADMIN_EMAILS
  end

  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = Constants::BASE_URL
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "pairwise@photocracy.org"
      @subject     = "[pairwise] "
      @content_type = "text/html"
      @sent_on     = Time.now
      @body[:user] = user
    end
end
