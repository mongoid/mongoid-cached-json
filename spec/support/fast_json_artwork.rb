class FastJsonArtwork
  include Mongoid::Document
  include Mongoid::CachedJson
  
  field :name, :default => "Artwork"
  field :display_name, :default => "Awesome Artwork"
  field :price, :default => 1000
  has_one :fast_json_image
  
  json_fields \
    :name => { },
    :display_name => { :properties => :public },
    :price => { :properties => :all },
    :image => { :type => :reference, :definition => :fast_json_image }
end

