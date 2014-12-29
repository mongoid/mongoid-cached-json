require File.join(File.dirname(__FILE__), 'json_polymorphic_referenced_foobar')

class JsonReferencedFoobar < JsonPolymorphicReferencedFoobar
  field :foo, type: String
end
