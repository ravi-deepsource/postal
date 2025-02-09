ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

$stdout.sync = true
$stderr.sync = true

require 'bundler/setup' # Set up gems listed in the Gemfile.

require_relative '../lib/postal/config'
Postal.check_config!

ENV['DATABASE_URL'] = Postal.database_url
ENV['RAILS_ENV'] = Postal.config.rails&.environment || 'development'
$0 = "[postal] #{ENV['PROC_NAME']}" if ENV['PROC_NAME']
