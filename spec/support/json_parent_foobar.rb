class JsonParentFoobar
  include Mongoid::Document
  include Mongoid::CachedJson

  belongs_to :json_polymorphic_referenced_foobar
  embeds_one :json_polymorphic_embedded_foobar

  json_fields \
    json_polymorphic_referenced_foobar: { type: :reference },
    json_polymorphic_embedded_foobar: { type: :reference }
end
