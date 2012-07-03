class PolyPerson
  include Mongoid::Document
  include Mongoid::CachedJson

  has_many :poly_posts, as: :postable

  json_fields \
    :id => {},
    :type => { :definition => :_type }

end




