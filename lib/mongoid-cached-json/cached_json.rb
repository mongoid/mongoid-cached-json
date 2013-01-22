# encoding: utf-8
module Mongoid
  module CachedJson
    extend ActiveSupport::Concern

    included do
      class_attribute :all_json_properties
      class_attribute :all_json_versions
      class_attribute :cached_json_field_defs
      class_attribute :cached_json_reference_defs
      class_attribute :hide_as_child_json_when
    end

    module ClassMethods

      # Define JSON fields for a class.
      #
      # @param [ hash ] defs JSON field definition.
      #
      # @since 1.0
      def json_fields(defs)
        self.hide_as_child_json_when = defs.delete(:hide_as_child_json_when) || lambda { |a| false }
        self.all_json_properties = [:short, :public, :all]
        cached_json_defs = Hash[defs.map { |k,v| [k, { :type => :callable, :properties => :short, :definition => k }.merge(v)] }]
        self.cached_json_field_defs = {}
        self.cached_json_reference_defs = {}
        # Collect all versions for clearing cache
        self.all_json_versions = cached_json_defs.map do |field, definition|
          [ :unspecified, definition[:version], Array(definition[:versions]) ]
        end.flatten.compact.uniq
        self.all_json_properties.each_with_index do |property, i|
          self.cached_json_field_defs[property] = Hash[cached_json_defs.find_all do |field, definition|
            self.all_json_properties.find_index(definition[:properties]) <= i and definition[:type] == :callable
          end]
          self.cached_json_reference_defs[property] = Hash[cached_json_defs.find_all do |field, definition|
            self.all_json_properties.find_index(definition[:properties]) <= i and definition[:type] == :reference
          end]
          # If the field is a reference and is just specified as a symbol, reflect on it to get metadata
          self.cached_json_reference_defs[property].to_a.each do |field, definition|
            if definition[:definition].is_a?(Symbol)
              self.cached_json_reference_defs[property][field][:metadata] = self.reflect_on_association(definition[:definition])
            end
          end
        end
        after_update :expire_cached_json
        after_destroy :expire_cached_json
      end

      # Materialize a cached JSON within a cache block.
      def materialize_cached_json(clazz, id, object_reference, options)
        is_top_level_json = options[:is_top_level_json] || false
        object_reference = clazz.where({ :_id => id }).first if !object_reference
        if !object_reference || (!is_top_level_json && options[:properties] != :all && clazz.hide_as_child_json_when.call(object_reference))
          nil
        else
          Hash[clazz.cached_json_field_defs[options[:properties]].map do |field, definition|
            # version match
            versions = ([definition[:version] ] | Array(definition[:versions])).compact
            next unless versions.empty? or versions.include?(options[:version])
            json_value = (definition[:definition].is_a?(Symbol) ? object_reference.send(definition[:definition]) : definition[:definition].call(object_reference))
            Mongoid::CachedJson.config.transform.each do |t|
              json_value = t.call(field, definition, json_value)
            end
            [field, json_value]
          end]
        end
      end

      # Given an object definition in the form of either an object or a class, id pair,
      # grab the as_json representation from the cache if possible, otherwise create
      # the as_json representation by loading the object from the database. For any
      # references in the object's JSON representation, we have to recursively materialize
      # the JSON by calling resolve_json_reference on each of them (which may, in turn,
      # call materialize_json)
      def materialize_json(options, object_def)
        return nil if !object_def[:object] and !object_def[:id]
        is_top_level_json = options[:is_top_level_json] || false
        if object_def[:object]
          object_reference = object_def[:object]
          clazz, id = object_def[:object].class, object_def[:object].id
        else
          object_reference = nil
          clazz, id = object_def[:clazz], object_def[:id]
        end
        key = self.cached_json_key(options, clazz, id)
        json = { :_ref => { :_clazz => self, :_key => key, :_materialize_cached_json => [ clazz, id, object_reference, options ] }}
        keys = KeyReferences.new
        keys.set_and_add(key, json)
        reference_defs = clazz.cached_json_reference_defs[options[:properties]]
        if !reference_defs.empty?
          object_reference = clazz.where({ :_id => id }).first if !object_reference
          if object_reference and (is_top_level_json or options[:properties] == :all or !clazz.hide_as_child_json_when.call(object_reference))
            json.merge!(Hash[reference_defs.map do |field, definition|
              json_properties_type = (options[:properties] == :all) ? :all : :short
              reference_keys, reference = clazz.resolve_json_reference(options.merge({ :properties => json_properties_type, :is_top_level_json => false}), object_reference, field, definition)
              if (reference.is_a?(Hash) && ref = reference[:_ref])
                ref[:_parent] = json
                ref[:_field] = field
              end
              keys.merge_set(reference_keys)
              [field, reference]
            end])
          end
        end
        [ keys, json ]
      end

      # Cache key.
      def cached_json_key(options, cached_class, cached_id)
        base_class_name = cached_class.collection_name.to_s.singularize.camelize
        "as_json/#{options[:version]}/#{base_class_name}/#{cached_id}/#{options[:properties]}/#{!!options[:is_top_level_json]}"
      end

      # If the reference is a symbol, we may be lucky and be able to figure out the as_json
      # representation by the (class, id) pair definition of the reference. That is, we may
      # be able to load the as_json representation from the cache without even getting the
      # model from the database and materializing it through Mongoid. We'll try to do this first.
      def resolve_json_reference(options, object, field, reference_def)
        keys = nil
        reference_json = nil
        if reference_def[:metadata]
          key = reference_def[:metadata].key.to_sym
          if reference_def[:metadata].polymorphic?
            clazz = reference_def[:metadata].inverse_class_name.constantize
          else
            clazz = reference_def[:metadata].class_name.constantize
          end
          if reference_def[:metadata].relation == Mongoid::Relations::Referenced::ManyToMany
            reference_json = object.send(key).map do |id|
              materialize_keys, json = materialize_json(options, { :clazz => clazz, :id => id })
              keys = keys ? keys.merge_set(materialize_keys) : materialize_keys
              json
            end.compact
          end
        end
        # If we get to this point and reference_json is still nil, there's no chance we can
        # load the JSON from cache so we go ahead and call as_json on the object.
        if ! reference_json
          reference_def_definition = reference_def[:definition]
          reference = reference_def_definition.is_a?(Symbol) ? object.send(reference_def_definition) : reference_def_definition.call(object)
          reference_json = nil
          if reference
            if reference.respond_to?(:as_json_partial)
              reference_keys, reference_json = reference.as_json_partial(options)
              keys = keys ? keys.merge_set(reference_keys) : reference_keys
            else
              reference_json = reference.as_json(options)
            end
          end
        end
        [ keys, reference_json ]
      end

    end

    # Check whether the cache supports :read_multi and prefetch the data if it does.
    def self.materialize_json_references_with_read_multi(key_refs, partial_json)
      unfrozen_keys = key_refs.keys.to_a.map(&:dup) if key_refs # see https://github.com/mperham/dalli/pull/320
      local_cache = unfrozen_keys && Mongoid::CachedJson.config.cache.respond_to?(:read_multi) ? Mongoid::CachedJson.config.cache.read_multi(unfrozen_keys) : {}
      Mongoid::CachedJson.materialize_json_references(key_refs, local_cache) if key_refs
      partial_json
    end

    # Materialize all the JSON references in place.
    def self.materialize_json_references(key_refs, local_cache = {})
      key_refs.each_pair do |key, refs|
        refs.each do |ref|
          _ref = ref.delete(:_ref)
          key = _ref[:_key]
          fetched_json = local_cache[key] if local_cache.has_key?(key)
          fetched_json ||= (local_cache[key] = Mongoid::CachedJson.config.cache.fetch(key, { :force => !! Mongoid::CachedJson.config.disable_caching }) do
            _ref[:_clazz].materialize_cached_json(* _ref[:_materialize_cached_json])
          end)
          if fetched_json
            ref.merge! fetched_json
          elsif _ref[:_parent]
            # a single _ref that resolved to a nil
            _ref[:_parent][_ref[:_field]] = nil
          end
        end
      end
    end

    # Return a partial JSON without resolved references and all the keys.
    def as_json_partial(options = {})
      options ||= {}
      if options[:properties] and ! self.all_json_properties.member?(options[:properties])
        raise ArgumentError.new("Unknown properties option: #{options[:properties]}")
      end
      # partial, unmaterialized JSON
      keys, partial_json = self.class.materialize_json({
        :properties => :short, :is_top_level_json => true, :version => Mongoid::CachedJson.config.default_version
      }.merge(options), { :object => self })
      [ keys, partial_json ]
    end

    # Fetch the partial JSON and materialize all JSON references.
    def as_json_cached(options = {})
      keys, json = as_json_partial(options)
      Mongoid::CachedJson.materialize_json_references_with_read_multi(keys, json)
    end

    # Return the JSON representation of the object.
    def as_json(options = {})
      as_json_cached(options)
    end

    # Expire all JSON entries for this class.
    def expire_cached_json
      self.all_json_properties.each do |properties|
        [true, false].each do |is_top_level_json|
          self.all_json_versions.each do |version|
            Mongoid::CachedJson.config.cache.delete(self.class.cached_json_key({
              :properties => properties, :is_top_level_json => is_top_level_json, :version => version
            }, self.class, self.id))
          end
        end
      end
    end

    class << self

      # Set the configuration options. Best used by passing a block.
      #
      # @example Set up configuration options.
      #   Mongoid::CachedJson.configure do |config|
      #     config.cache = Rails.cache
      #   end
      #
      # @return [ Config ] The configuration obejct.
      def configure
        block_given? ? yield(Mongoid::CachedJson::Config) : Mongoid::CachedJson::Config
      end
      alias :config :configure
    end

  end
end
