module Mongoid
  class Criteria

    def as_json_partial(options = {})
      json_keys = nil
      json = map do |i|
        if i.respond_to?(:as_json_partial)
          partial_json_keys, partial_json = i.as_json_partial(options)
          json_keys = json_keys ? json_keys.merge_set(partial_json_keys) : partial_json_keys
          partial_json
        else
          i.as_json(options)
        end
      end
      [ json_keys, json ]
    end

    def as_json(options = {})
      json_keys, json = as_json_partial(options)
      Mongoid::CachedJson.materialize_json_references_with_read_multi(json_keys, json)
    end

  end
end
