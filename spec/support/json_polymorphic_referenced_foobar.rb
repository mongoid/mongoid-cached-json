class JsonPolymorphicReferencedFoobar
  include Mongoid::Document
  include Mongoid::CachedJson

  has_one :json_parent_foobar

  json_fields \
    :foo => { :properties => :short }

end
