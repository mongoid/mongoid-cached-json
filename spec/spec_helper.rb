if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start do
    track_files 'lib/**/*.rb'
    add_filter '/spec/'
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'mongoid-cached-json'
require 'mongoid-compatibility'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each do |f|
  require f
end

Mongoid.configure do |config|
  config.connect_to('cached_json_test')
  if Mongoid::VERSION.to_i >= 5
    config.clients['default']['hosts'] = [ENV.fetch('MONGODB_HOST', 'localhost:27017')]
  else
    config.sessions['default']['hosts'] = [ENV.fetch('MONGODB_HOST', 'localhost:27017')]
  end
end

if ActiveSupport::VERSION::MAJOR >= 6
  require 'active_support/cache/mem_cache_store'
else
  require 'active_support/cache/dalli_store'
end

MEMCACHE_STORE = ActiveSupport::VERSION::MAJOR >= 6 ? :mem_cache_store : :dalli_store
MEMCACHE_STORE_CLASS = ActiveSupport::Cache.lookup_store(MEMCACHE_STORE).class

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.after :each do
    Mongoid::CachedJson.config.reset!
  end
  config.before :all do
    Mongoid.logger.level = Logger::INFO
    Mongo::Logger.logger.level = Logger::INFO if Mongoid::Compatibility::Version.mongoid5?
  end
end
