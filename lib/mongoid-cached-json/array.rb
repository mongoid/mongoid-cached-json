class Array
  def as_json_partial(options = {})
    keys = nil
    json = map do |i|
      if i.respond_to?(:as_json_partial)
        partial_keys, json = i.as_json_partial(options)
        keys = keys ? keys.merge_set(partial_keys) : partial_keys
        json
      else
        i.as_json(options)
      end
    end
    [ keys, json ]
  end

  def as_json(options = {})
    keys, json = as_json_partial(options)
      puts "keys: #{keys.to_a.join(', ')}"
      puts "json: #{json}"
    Mongoid::CachedJson.materialize_json_references_with_read_multi(keys, json)
  end
end
