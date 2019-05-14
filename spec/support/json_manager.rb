class JsonManager
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name
  field :ssn, default: '123-45-6789'
  has_many :json_employees

  if Mongoid::Compatibility::Version.mongoid5_or_older?
    belongs_to :supervisor, class_name: 'JsonSupervisor'
  else
    belongs_to :supervisor, class_name: 'JsonSupervisor', required: false
  end

  json_fields \
    name: {},
    ssn: { properties: :all },
    employees: { type: :reference, definition: :json_employees }
end
