class JsonManager
  include Mongoid::Document
  include Mongoid::CachedJson
  
  field :name
  field :ssn, :default => "123-45-6789"
  has_many :json_employees
  
  json_fields \
    :name => {},
    :ssn => { :properties => :all },
    :employees => { :type => :reference, :definition => :json_employees }
end

