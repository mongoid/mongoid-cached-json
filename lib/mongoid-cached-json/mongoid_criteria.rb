module Mongoid
  class Criteria
    def as_json_partial(options = {})
      keys = nil
      json = map do |i|
        partial_keys, json = i.as_json_partial(options)
        keys = (keys || Set.new).union(partial_keys) if partial_keys
        json
      end
      [ keys, json ]
    end

    def as_json(options = {})
      _, json = as_json_partial(options)
      Mongoid::CachedJson.materialize_json_references(json)
    end
  end
end
