class Hash

  def as_json_partial(options = {})
    json_keys = nil
    json = inject({}) do |h, (k, v)|
      if v.respond_to?(:as_json_partial)
        partial_json_keys, partial_json = v.as_json_partial(options)
        json_keys = json_keys ? json_keys.merge_set(partial_json_keys) : partial_json_keys
        h[k] = partial_json
      else
        h[k] = v.as_json(options)
      end
      h
    end
    [ json_keys, json ]
  end

  def as_json(options = {})
    json_keys, json = as_json_partial(options)
    Mongoid::CachedJson.materialize_json_references_with_read_multi(json_keys, json)
  end

end
