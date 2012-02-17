class FastJsonUrl
  include Mongoid::Document
  include CachedJson

  field :url, :default => "http://art.sy/omg.jpeg"
  field :is_public, :default => false
  has_and_belongs_to_many :fast_json_image

  json_fields \
    :url => {},
    :is_public => { :properties => :all }
end

