class JsonSupervisor
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name
  field :ssn, default: '123-45-6789'
  has_many :json_managers

  json_fields \
    name: {},
    ssn: { properties: :all },
    managers: { type: :reference, definition: :json_managers, properties: :all, reference_properties: :short }
end
