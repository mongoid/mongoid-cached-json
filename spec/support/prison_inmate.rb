class PrisonInmate
  include Mongoid::Document
  include Mongoid::CachedJson

  field :nickname
  embedded_in :prison_cell, :inverse_of => :inmates
  belongs_to :person

  json_fields \
    :nickname => {},
    :person => { :type => :reference }

end

