class Array
  def as_json_partial(options)
    keys = nil
    json = map do |i|
      if i.respond_to?(:as_json_partial)
        partial_keys, json = i.as_json_partial(options)
        keys = (keys || Set.new).union(partial_keys)
        json
      else
        i.as_json(options)
      end
    end
    [ keys, json ]
  end
end
