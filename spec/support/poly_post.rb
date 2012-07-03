class PolyPost
  include Mongoid::Document
  include Mongoid::CachedJson

  belongs_to :postable, :polymorphic => true

  json_fields \
    :parent => { :type => :reference, :definition => :postable }

end
