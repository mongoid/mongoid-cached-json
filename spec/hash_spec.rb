require 'spec_helper'

describe Hash do
  it "materializes multiple objects that may or may not respond to as_json_partial" do
    foobar1 = JsonFoobar.create({ :foo => "FOO1", :baz => "BAZ", :bar => "BAR" })
    foobar2 = JsonFoobar.create({ :foo => "FOO2", :baz => "BAZ", :bar => "BAR" })
    {
      :x => :y,
      :foobar1 => foobar1,
      :foobar2 => foobar2,
      :z => {
        :foobar1 => foobar1
      },
      :t => [ foobar1, :y ]
    }.as_json.should == {
      :x => "y",
      :foobar1 => { :foo => "FOO1", "Baz" => "BAZ", :default_foo => "DEFAULT_FOO" },
      :foobar2 => { :foo => "FOO2", "Baz"=>"BAZ", :default_foo => "DEFAULT_FOO" },
      :z => { :foobar1 => { :foo => "FOO1", "Baz" => "BAZ", :default_foo => "DEFAULT_FOO" } },
      :t => [ { :foo=>"FOO1", "Baz" => "BAZ", :default_foo => "DEFAULT_FOO" }, "y" ]
    }
  end
end

