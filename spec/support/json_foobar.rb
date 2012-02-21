class JsonFoobar
  include Mongoid::Document
  include Mongoid::CachedJson

  field :foo
  field :bar
  field :baz
  field :default_foo, :default => "DEFAULT_FOO"

  json_fields_for :v1, \
    :foo => { :properties => :short },
    :bar => { :properties => :public },
    "Baz" => { :definition => :baz },
    :renamed_baz => { :properties => :all, :definition => :baz },
    :default_foo => { }, # default value for properties is :short
    :computed_field => { :properties => :all, :definition => lambda { |x| x.foo + x.bar } }

  json_fields_for :v2,
    foo_that_is_baz: { definition: :baz }    

end

