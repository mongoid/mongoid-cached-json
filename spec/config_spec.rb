require 'spec_helper'

describe Mongoid::CachedJson::Config do
  before :each do
    @cache = Mongoid::CachedJson::Config.cache
  end
  after :each do
    Mongoid::CachedJson::Config.cache = @cache
  end
  it 'configures a cache store' do
    cache = Class.new
    Mongoid::CachedJson.configure do |config|
      config.cache = cache
    end
    expect(cache).to receive(:fetch).once
    JsonFoobar.new.as_json
  end
  it 'sets disable_caching to false' do
    expect(Mongoid::CachedJson.config.disable_caching).to be_falsey
  end
end
