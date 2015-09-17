require 'spec_helper'

describe Mongoid::Criteria do
  it 'mongoid_criteria' do
    tool_box = ToolBox.create!(color: 'red')
    Tool.create!(name: 'hammer', tool_box: tool_box)
    Tool.create!(name: 'screwdriver', tool_box: tool_box)
    expect(Tool.where(tool_box_id: tool_box.id).as_json(properties: :all)).to eq([
      { tool_box: { color: 'red' }, name: 'hammer' },
      { tool_box: { color: 'red' }, name: 'screwdriver' }
    ])
  end
  context 'without read_multi' do
    before :each do
      Mongoid::CachedJson.config.cache.instance_eval { undef :read_multi }
    end
    it 'materializes multiple objects using a single partial' do
      tool_box = ToolBox.create!(color: 'red')
      Tool.create!(name: 'hammer', tool_box: tool_box)
      Tool.create!(name: 'screwdriver', tool_box: tool_box)
      # once per tool and once for the tool box
      expect(Mongoid::CachedJson.config.cache).to receive(:fetch).exactly(3).times.and_return(
        x: :y
      )
      expect(tool_box.tools.as_json(properties: :all)).to eq([
        { tool_box: { x: :y }, x: :y },
        { tool_box: { x: :y }, x: :y }
      ])
    end
  end
  context 'with read_multi' do
    it 'responds to read_multi' do
      expect(Mongoid::CachedJson.config.cache).to respond_to :read_multi
    end
    it 'materializes multiple objects using a single partial' do
      tool_box = ToolBox.create!(color: 'red')
      tool1 = Tool.create!(name: 'hammer', tool_box: tool_box)
      tool2 = Tool.create!(name: 'screwdriver', tool_box: tool_box)
      # once per tool and once for the tool box
      keys = [
        "as_json/unspecified/Tool/#{tool1.id}/all/true",
        "as_json/unspecified/ToolBox/#{tool_box.id}/all/false",
        "as_json/unspecified/Tool/#{tool2.id}/all/true"
      ]
      expect(Mongoid::CachedJson.config.cache).to receive(:read_multi).once.with(*keys).and_return(
        keys[0] => { x: :y },
        keys[1] => { x: :y },
        keys[2] => { x: :y }
      )
      expect(tool_box.tools.as_json(properties: :all)).to eq([
        { tool_box: { x: :y }, x: :y },
        { tool_box: { x: :y }, x: :y }
      ])
    end
    it 'does not call fetch for missing objects, only write' do
      tool_box = ToolBox.create!(color: 'red')
      tool1 = Tool.create!(name: 'hammer', tool_box: tool_box)
      tool2 = Tool.create!(name: 'screwdriver', tool_box: tool_box)
      # once per tool and once for the tool box
      keys = [
        "as_json/unspecified/Tool/#{tool1.id}/all/true",
        "as_json/unspecified/ToolBox/#{tool_box.id}/all/false",
        "as_json/unspecified/Tool/#{tool2.id}/all/true"
      ]
      expect(Mongoid::CachedJson.config.cache).to receive(:read_multi).once.with(*keys).and_return(
        keys[0] => { x: :y },
        keys[1] => { x: :y }
      )
      # read_multi returned only 2 of 3 things, don't call fetch, just store the third value
      expect(Mongoid::CachedJson.config.cache).not_to receive(:fetch)
      expect(Mongoid::CachedJson.config.cache).to receive(:write).with("as_json/unspecified/Tool/#{tool2.id}/all/true", name: 'screwdriver')
      expect(tool_box.tools.as_json(properties: :all)).to eq([
        { tool_box: { x: :y }, x: :y },
        { tool_box: { x: :y }, name: 'screwdriver' }
      ])
    end
  end
end
