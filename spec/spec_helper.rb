$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rasn1'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include Binary
end
