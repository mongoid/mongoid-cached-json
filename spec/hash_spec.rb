require 'spec_helper'

describe Hash do
  it 'hash' do
    expect({ x: 'x', y: 'y' }.as_json).to eq(x: 'x', y: 'y')
  end
  it 'materializes multiple objects that may or may not respond to as_json_partial' do
    foobar1 = JsonFoobar.create(foo: 'FOO1', baz: 'BAZ', bar: 'BAR')
    foobar2 = JsonFoobar.create(foo: 'FOO2', baz: 'BAZ', bar: 'BAR')
    expect({
      :x => :y,
      :foobar1 => foobar1,
      :foobar2 => foobar2,
      :z => {
        foobar1: foobar1
      },
      :t => [foobar1, :y],
      'empty' => []
    }.as_json).to eq(
      :x => 'y',
      :foobar1 => { :foo => 'FOO1', 'Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO' },
      :foobar2 => { :foo => 'FOO2', 'Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO' },
      :z => { foobar1: { :foo => 'FOO1', 'Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO' } },
      :t => [{ :foo => 'FOO1', 'Baz' => 'BAZ', :default_foo => 'DEFAULT_FOO' }, 'y'],
      'empty' => []
    )
  end
  context 'without read_multi' do
    before :each do
      Mongoid::CachedJson.config.cache.instance_eval { undef :read_multi }
    end
    it 'uses a local cache to fetch repeated objects' do
      tool = Tool.create!(name: 'hammer')
      expect(Mongoid::CachedJson.config.cache).to receive(:fetch).once.and_return(
        x: :y
      )
      expect({
        t1: tool,
        t2: tool,
        t3: tool
      }.as_json(properties: :all)).to eq(
        t1: { tool_box: nil, x: :y },
        t2: { tool_box: nil, x: :y },
        t3: { tool_box: nil, x: :y }
      )
    end
  end
  context 'with read_multi' do
    it 'uses a local cache to fetch repeated objects' do
      tool = Tool.create!(name: 'hammer')
      tool_key = "as_json/unspecified/Tool/#{tool.id}/all/true"
      expect(Mongoid::CachedJson.config.cache).to receive(:read_multi).once.with(tool_key).and_return(
        tool_key => { x: :y }
      )
      expect({
        t1: tool,
        t2: tool,
        t3: tool
      }.as_json(properties: :all)).to eq(
        t1: { tool_box: nil, x: :y },
        t2: { tool_box: nil, x: :y },
        t3: { tool_box: nil, x: :y }
      )
    end
  end
end
