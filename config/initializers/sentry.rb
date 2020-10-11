require 'postal/config'

if Postal.config.general&.exception_url
  require 'raven'
  Raven.configure do |config|
    config.dsn = Postal.config.general.exception_url
    config.environments = ['production']
    config.environments << 'development' if ENV['DEV_EXCEPTIONS']
    config.silence_ready = true
    config.tags = { process: ENV['PROC_NAME'] }
  end
end
