require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  # associations
  has_many :questions, :dependent => :destroy
  has_many :items, :dependent => :destroy
  has_many :voters, :dependent => :destroy
  has_many :prompts, :through => :questions, :dependent => :destroy

  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(email_login, password)
    return nil if email_login.blank? || password.blank?
    # need to get the salt, for legacy support check login before email
    u = find_in_state(:first, :active, :conditions => { :login => email_login }) ||
      find_in_state(:first, :admin, :conditions => { :login => email_login }) ||
      find_in_state(:first, :active, :conditions => { :email => email_login }) ||
      find_in_state(:first, :admin, :conditions => { :email => email_login })
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  # Delete all the user's items and their connections to stats, votes, prompts.
  # Delete all stats, items_questions, prompt_requests, and prompts for the
  # user's questions.
  def destroy_items
    item_ids_str = item_ids.join(',')
    prompt_ids_str = prompt_ids.join(',')
    question_ids_str = question_ids.join(',')
    Vote.delete_all("prompt_id IN (#{prompt_ids_str})") unless prompt_ids_str.empty?
    unless item_ids_str.empty?
      ActiveRecord::Base.connection.execute("DELETE FROM items_stats WHERE item_id IN (#{item_ids_str})")
      ActiveRecord::Base.connection.execute("DELETE FROM items_votes WHERE item_id IN (#{item_ids_str})")
      ActiveRecord::Base.connection.execute("DELETE FROM items_prompts WHERE item_id IN (#{item_ids_str})")
    end
    Item.delete_all("user_id=#{id}")
    unless question_ids_str.empty?
      Stat.delete_all("question_id IN (#{question_ids_str})")
      ItemsQuestion.delete_all("question_id IN (#{question_ids_str})")
      PromptRequest.delete_all("question_id IN (#{question_ids_str})")
      Prompt.delete_all("question_id IN (#{question_ids_str})")
    end
  end

  # Delete all data connected to the user.
  def destroy_data
    item_ids_str = item_ids.join(',')
    prompt_ids_str = prompt_ids.join(',')
    question_ids_str = question_ids.join(',')
    voter_ids_str = voter_ids.join(',')
    Vote.delete_all("prompt_id IN (#{prompt_ids_str})") unless prompt_ids_str.empty?
    unless item_ids_str.empty?
      ActiveRecord::Base.connection.execute("DELETE FROM items_stats WHERE item_id IN (#{item_ids_str})")
      ActiveRecord::Base.connection.execute("DELETE FROM items_votes WHERE item_id IN (#{item_ids_str})")
      ActiveRecord::Base.connection.execute("DELETE FROM items_prompts WHERE item_id IN (#{item_ids_str})")
    end
    Item.delete_all("user_id=#{id}")
    unless question_ids_str.empty?
      Stat.delete_all("question_id IN (#{question_ids_str})")
      ItemsQuestion.delete_all("question_id IN (#{question_ids_str})")
      PromptRequest.delete_all("question_id IN (#{question_ids_str})")
      Prompt.delete_all("question_id IN (#{question_ids_str})")
    end
    Question.delete_all("user_id=#{id}")
    Feature.delete_all("voter_id IN (#{voter_ids_str})") unless voter_ids_str.empty?
    Voter.delete_all("user_id=#{id}")
  end

  protected
    def make_activation_code
      self.deleted_at = nil
      self.activation_code = self.class.make_token
    end
end
