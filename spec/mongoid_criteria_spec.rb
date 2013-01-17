require 'spec_helper'

describe Mongoid::Criteria do
  it "materializes multiple objects using a single partial" do
    tool_box = ToolBox.create!({ :color => "red" })
    tool1 = Tool.create!({ :name => "hammer", :tool_box => tool_box })
    tool1 = Tool.create!({ :name => "screwdriver", :tool_box => tool_box })
    # once per tool and once for the tool box
    Mongoid::CachedJson.config.cache.should_receive(:fetch).exactly(3).times.and_return({
      :x => :y
    })
    tool_box.tools.as_json({ properties: :all }).should == [
      { :tool_box => { :x => :y }, :x => :y },
      { :tool_box => { :x => :y }, :x => :y }
    ]
  end
end

