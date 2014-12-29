class AwesomeArtwork
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name
  has_one :awesome_image

  json_fields \
    name: {},
    image: { type: :reference, definition: :awesome_image }
end
