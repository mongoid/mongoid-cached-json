# Keep key references to be replaced once the entire JSON is available.
# encoding: utf-8
module Mongoid
  module CachedJson
    class KeyReferences < Hash

      def merge_set(keys)
        if keys
          keys.each_pair do |k, jsons|
            self[k] ||= []
            self[k].concat(jsons)
          end
        end
        self
      end

      def set_and_add(key, json)
        self[key] ||= []
        self[key] << json
        self
      end

    end
  end
end

