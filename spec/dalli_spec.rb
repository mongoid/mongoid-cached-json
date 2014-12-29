require 'spec_helper'
require 'active_support/cache/dalli_store'

describe ActiveSupport::Cache::DalliStore do
  before :each do
    @cache = Mongoid::CachedJson::Config.cache
    Mongoid::CachedJson.configure do |config|
      config.cache = ActiveSupport::Cache.lookup_store(:dalli_store)
    end
  end
  after :each do
    Mongoid::CachedJson::Config.cache = @cache
  end
  it 'uses dalli_store' do
    expect(Mongoid::CachedJson.config.cache).to be_a ActiveSupport::Cache::DalliStore
  end
  context 'read_multi' do
    context 'array' do
      it 'uses a local cache to fetch repeated objects' do
        options = { properties: :all, is_top_level_json: true, version: :unspecified }
        tool1 = Tool.create!(name: 'hammer')
        tool1_key = Tool.cached_json_key(options, Tool, tool1.id)
        tool2 = Tool.create!(name: 'screwdriver')
        tool2_key = Tool.cached_json_key(options, Tool, tool2.id)
        expect(Mongoid::CachedJson.config.cache).not_to receive(:fetch)
        expect(Mongoid::CachedJson.config.cache).to receive(:read_multi).with(tool1_key, tool2_key).once.and_return(
          tool1_key => { _id: tool1.id.to_s },
          tool2_key => { _id: tool2.id.to_s }
        )
        expect([tool1, tool2].as_json(properties: :all)).to eq([
          { tool_box: nil, _id: tool1.id.to_s },
          { tool_box: nil, _id: tool2.id.to_s }
        ])
      end
    end
  end
end
