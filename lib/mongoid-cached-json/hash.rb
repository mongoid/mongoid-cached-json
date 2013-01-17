class Hash

  def as_json_partial(options = {})
    keys = nil
    json = inject({}) do |h, (k, v)|
      if v.respond_to?(:as_json_partial)
        partial_keys, partial_json = v.as_json_partial(options)
        keys = (keys || Set.new).union(partial_keys) if partial_keys
        h[k] = partial_json
      else
        h[k] = v.as_json(options)
      end
      h
    end
    [ keys, json ]
  end

  def as_json(options = {})
    keys, json = as_json_partial(options)
    Mongoid::CachedJson.materialize_json_references_with_read_multi(keys, json)
  end

end
