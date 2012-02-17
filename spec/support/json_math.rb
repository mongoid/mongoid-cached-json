class JsonMath
  include Mongoid::Document
  include Mongoid::CachedJson

  field :number

  json_fields \
    :number => {}
    
end

