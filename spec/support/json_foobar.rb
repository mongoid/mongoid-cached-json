class JsonFoobar
  include Mongoid::Document
  include Mongoid::CachedJson

  field :foo
  field :bar
  field :baz
  field :default_foo, default: 'DEFAULT_FOO'

  json_fields \
    :foo => { properties: :short },
    :bar => { properties: :public },
    'Baz' => { definition: :baz, version: :unspecified },
    'Taz' => { definition: :baz, version: :v2 },
    'Naz' => { definition: :baz, versions: [:v2, :v3] },
    :renamed_baz => { properties: :all, definition: :baz },
    :default_foo => {}, # default value for properties is :short
    :computed_field => { properties: :all, definition: lambda { |x| "#{x.foo}#{x.bar}" } }
end
