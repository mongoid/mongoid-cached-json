class ToolBox
  include Mongoid::Document
  include Mongoid::CachedJson

  field :color
  has_many :tools

  json_fields \
    color: {}
end
