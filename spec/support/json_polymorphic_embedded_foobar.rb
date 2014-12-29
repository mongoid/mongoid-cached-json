class JsonPolymorphicEmbeddedFoobar
  include Mongoid::Document
  include Mongoid::CachedJson

  embedded_in :json_parent_foobar

  json_fields \
    foo: { properties: :short }
end
