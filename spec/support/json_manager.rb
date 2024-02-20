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

  def has_left_handed_employee?
    json_employees.any? { |e| e.is_left_handed? }
  end

  json_fields \
    name: {},
    ssn: { properties: :all },
    employees: { type: :reference, definition: :json_employees },
    has_left_handed_employee: { type: :reference, definition: :has_left_handed_employee? }
end
