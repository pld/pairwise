RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

PRODUCTION = false
LOG_DETAIL = !PRODUCTION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'hodel_3000_compliant_logger' if LOG_DETAIL

Rails::Initializer.run do |config|
  config.gem 'rubyist-aasm', :lib => 'aasm'
  config.gem 'libxml-ruby', :lib => 'libxml'

  # Use the Hodel3000 compliant logger
  config.logger = Hodel3000CompliantLogger.new(config.log_path) if LOG_DETAIL

  # Use default local time.
  # config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :key => '_pairwise_session',
    :secret      => ''
  }
  config.action_controller.session_store = :active_record_store
  config.action_mailer.delivery_method = :smtp
end