class Tool
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name
  belongs_to :tool_box

  json_fields \
    name: {},
    tool_box: { type: :reference }
end
