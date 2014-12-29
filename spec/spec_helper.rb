$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'mongoid-cached-json'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each do |f|
  require f
end

Mongoid.configure do |config|
  config.connect_to('cached_json_test')
end

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.after :each do
    Mongoid::CachedJson.config.reset!
  end
end
