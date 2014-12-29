class PolyCompany
  include Mongoid::Document
  include Mongoid::CachedJson

  has_many :poly_posts, as: :postable

  json_fields \
    id: {},
    type: { definition: lambda { |x| x.class.name } }
end
