module Postal
  VERSION = '1.0.0'.freeze
  REVISION = nil
  CHANNEL = 'dev'.freeze

  def self.version
    [VERSION, REVISION, CHANNEL].compact.join('-')
  end
end
