class FastJsonImage
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name, default: 'Image'
  belongs_to :fast_json_artwork
  has_and_belongs_to_many :fast_json_urls

  json_fields \
    name: {},
    urls: { type: :reference, definition: :fast_json_urls }
end
