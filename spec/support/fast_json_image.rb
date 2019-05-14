class FastJsonImage
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name, default: 'Image'
  if Mongoid::Compatibility::Version.mongoid5_or_older?
    belongs_to :fast_json_artwork
  else
    belongs_to :fast_json_artwork, required: false
  end
  has_and_belongs_to_many :fast_json_urls

  json_fields \
    name: {},
    urls: { type: :reference, definition: :fast_json_urls }
end
