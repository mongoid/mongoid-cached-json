class PrisonInmate
  include Mongoid::Document
  include Mongoid::CachedJson
  
  field :nickname
  embedded_in :prison_cell, :inverse_of => :inmates
  referenced_in :person
  
  json_fields \
    :nickname => {},
    :person => { :type => :reference }
    
end

