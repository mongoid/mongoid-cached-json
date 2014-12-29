class AwesomeImage
  include Mongoid::Document
  include Mongoid::CachedJson

  field :name
  field :nickname, default: 'Mona'
  field :url, default: 'http://example.com/404.html'
  belongs_to :awesome_artwork

  json_fields \
    name: {},
    nickname: {},
    url: { properties: :public }
end
