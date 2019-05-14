class Tool
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name

  if Mongoid::Compatibility::Version.mongoid5_or_older?
    belongs_to :tool_box
  else
    belongs_to :tool_box, required: false
  end

  json_fields \
    name: {},
    tool_box: { type: :reference }
end
