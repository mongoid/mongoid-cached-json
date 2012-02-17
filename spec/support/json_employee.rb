class JsonEmployee
  include Mongoid::Document
  include Mongoid::CachedJson
  
  field :name
  field :nickname, :default => "My Favorite"
  belongs_to :json_manager

  json_fields \
    :name => {},
    :nickname => { :properties => :all }
end

