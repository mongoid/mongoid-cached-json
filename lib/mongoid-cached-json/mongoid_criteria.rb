module Mongoid
  class Criteria
    def as_json_partial(options = {})
      keys = nil
      json = map do |i|
        if i.respond_to?(:as_json_partial)
          partial_keys, partial_json = i.as_json_partial(options)
          keys = keys ? keys.merge_set(partial_keys) : partial_keys
          partial_json
        else
          i.as_json(options)
        end
      end
      [ keys, json ]
    end

    def as_json(options = {})
      keys, json = as_json_partial(options)
      Mongoid::CachedJson.materialize_json_references_with_read_multi(keys, json)
    end
  end
end
