class Person
  include Mongoid::Document
  include Mongoid::CachedJson

  field :first
  field :last
  field :middle

  def name
    [ first, middle, last ].compact.join(" ")
  end

  json_fields \
    :first => { :versions => [ :v2, :v3 ] },
    :last => { :versions => [ :v2, :v3 ] },
    :middle => { :versions => [ :v2, :v3 ] },
    :born => { :versions => :v3 },
    :name => { :definition => :name }

end

