class KeyReferences < Hash

  def merge_set(keys)
    return unless keys
    keys.each_pair do |k, jsons|
      self[k] ||= []
      self[k].concat(jsons)
    end
    self
  end

  def set_and_add(key, json)
    self[key] ||= []
    self[key] << json
    self
  end

end
