class PrisonCell
  include Mongoid::Document
  include Mongoid::CachedJson

  field :number
  embeds_many :inmates, class_name: 'PrisonInmate'

  json_fields \
    number: {},
    inmates: { type: :reference }
end
