class JsonTransform
  include Mongoid::Document
  include Mongoid::CachedJson

  field :upcase
  field :downcase
  field :nochange

  json_fields \
    upcase: { transform: :upcase },
    downcase: { transform: :downcase },
    nochange: {}
end
