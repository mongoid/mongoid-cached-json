class SometimesSecret
  include Mongoid::Document
  include Mongoid::CachedJson

  field :secret, default: 'Afraid of the dark'
  field :should_tell_secret, type: Boolean
  belongs_to :secret_parent

  json_fields hide_as_child_json_when: lambda { |x| !x.should_tell_secret },
              secret: {}
end
