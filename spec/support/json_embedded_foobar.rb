require File.join(File.dirname(__FILE__), 'json_polymorphic_embedded_foobar')

class JsonEmbeddedFoobar < JsonPolymorphicEmbeddedFoobar
  field :foo, type: String
end
