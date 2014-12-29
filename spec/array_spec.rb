require 'spec_helper'

describe Array do
  it 'array' do
    [:x, 'y'].as_json.should == %w(x y)
  end
  it 'materializes multiple objects that may or may not respond to as_json_partial' do
    foobar1 = JsonFoobar.create!(foo: 'FOO1', baz: 'BAZ', bar: 'BAR')
    foobar2 = JsonFoobar.create!(foo: 'FOO2', baz: 'BAZ', bar: 'BAR')
    [[:x, :y], foobar1, foobar2, foobar1, { x: foobar1, y: 'z' }].as_json.should == [
      %w(x y),
      { :foo => 'FOO1', 'Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO' },
      { :foo => 'FOO2', 'Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO' },
      { :foo => 'FOO1', 'Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO' },
      { x: { :foo => 'FOO1', 'Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO' }, y: 'z' }
    ]
  end
  context 'without read_multi' do
    before :each do
      Mongoid::CachedJson.config.cache.instance_eval { undef :read_multi }
    end
    it 'uses a local cache to fetch repeated objects' do
      tool = Tool.create!(name: 'hammer')
      Mongoid::CachedJson.config.cache.should_receive(:fetch).once.and_return(
        x: :y
      )
      [tool, tool, tool].as_json(properties: :all).should == [
        { tool_box: nil, x: :y },
        { tool_box: nil, x: :y },
        { tool_box: nil, x: :y }
      ]
    end
  end
  context 'with read_multi' do
    it 'uses a local cache to fetch repeated objects' do
      tool = Tool.create!(name: 'hammer')
      tool_key = "as_json/unspecified/Tool/#{tool.id}/all/true"
      Mongoid::CachedJson.config.cache.should_receive(:read_multi).once.with(tool_key).and_return(
        tool_key => { x: :y }
      )
      [tool, tool, tool].as_json(properties: :all).should == [
        { tool_box: nil, x: :y },
        { tool_box: nil, x: :y },
        { tool_box: nil, x: :y }
      ]
    end
  end
end
