class SecretParent
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name
  has_one :sometimes_secret

  json_fields \
    :name => {},
    :child => { :definition => :sometimes_secret, :type => :reference }
end

