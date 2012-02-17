require 'spec_helper'

describe CachedJson::Config do
  before :each do
    @cache= CachedJson::Config.cache
  end
  after :each do
    CachedJson::Config.cache = @cache
  end
  it "configures a cache store" do
    cache = Class.new
    CachedJson.configure do |config|
      config.cache = cache
    end
    cache.should_receive(:fetch).once
    JsonFoobar.new.as_json
  end
end
