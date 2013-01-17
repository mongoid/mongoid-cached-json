require 'spec_helper'

describe Array do
  it "materializes multiple objects that may or may not respond to as_json_partial" do
    foobar1 = JsonFoobar.create!({ :foo => "FOO1", :baz => "BAZ", :bar => "BAR" })
    foobar2 = JsonFoobar.create!({ :foo => "FOO2", :baz => "BAZ", :bar => "BAR" })
    [ [ :x, :y ], foobar1, foobar2, foobar1 ].as_json.should == [
        [ "x", "y" ],
        { :foo => "FOO1", "Baz" => "BAZ", :default_foo => "DEFAULT_FOO" },
        { :foo => "FOO2", "Baz" => "BAZ", :default_foo => "DEFAULT_FOO" },
        { :foo => "FOO1", "Baz" => "BAZ", :default_foo => "DEFAULT_FOO" }
      ]
  end
  it "uses a local cache to fetch repeated objects" do
    tool = Tool.create!({ :name => "hammer" })
    Mongoid::CachedJson.config.cache.should_receive(:fetch).once.and_return({
      :x => :y
    })
    [ tool, tool, tool ].as_json({ properties: :all }).should == [
      { :tool_box => nil, :x => :y },
      { :tool_box => nil, :x => :y },
      { :tool_box => nil, :x => :y },
    ]
  end
end

