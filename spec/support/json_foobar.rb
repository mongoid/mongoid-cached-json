class JsonFoobar
  include Mongoid::Document
  include CachedJson

  field :foo
  field :bar
  field :baz
  field :default_foo, :default => "DEFAULT_FOO"

  json_fields \
    :foo => { :properties => :short },
    :bar => { :properties => :public },
    "Baz" => { :definition => :baz },
    :renamed_baz => { :properties => :all, :definition => :baz },
    :default_foo => { }, # default value for properties is :short
    :computed_field => { :properties => :all, :definition => lambda { |x| x.foo + x.bar } }
    
end

