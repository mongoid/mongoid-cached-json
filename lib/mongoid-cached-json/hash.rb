class Hash
  def as_json_partial(options)
    keys = nil
    json = inject({}) do |h, (k, v)|
      if v.respond_to?(:as_json_partial)
        partial_keys, json = v.as_json_partial(options)
        keys = (keys || Set.new).union(partial_keys)
        h[k] = json
      else
        h[k] = v.as_json(options)
      end
    end
    [ keys, json ]
  end
end
