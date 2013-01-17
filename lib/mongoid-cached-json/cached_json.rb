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
        before_save :expire_cached_json
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
        keys = []
        is_top_level_json = options[:is_top_level_json] || false
        if object_def[:object]
          object_reference = object_def[:object]
          clazz, id = object_def[:object].class, object_def[:object].id
        else
          object_reference = nil
          clazz, id = object_def[:clazz], object_def[:id]
        end
        key = self.cached_json_key(options, clazz, id)
        json = { :_ref => { :_key => key, :_materialize_cached_json => [ clazz, id, object_reference, options ] }}
        reference_defs = clazz.cached_json_reference_defs[options[:properties]]
        if !reference_defs.empty?
          object_reference = clazz.where({ :_id => id }).first if !object_reference
          if object_reference and (is_top_level_json or options[:properties] == :all or !clazz.hide_as_child_json_when.call(object_reference))
            json.merge!(Hash[reference_defs.map do |field, definition|
              json_properties_type = (options[:properties] == :all) ? :all : :short
              reference_keys, reference = clazz.resolve_json_reference(options.merge({ :properties => json_properties_type, :is_top_level_json => false}), object_reference, field, definition)
              keys.concat reference_keys if reference_keys
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
        keys = []
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
              keys.concat materialize_keys if materialize_keys
              json
            end.compact
          elsif reference_def[:metadata].relation == Mongoid::Relations::Referenced::In
            materialize_keys, json = materialize_json(options, { :clazz => clazz, :id => object.send(key) })
            keys.concat materialize_keys if materialize_keys
            json
          end
        end
        # If we get to this point and reference_json is still nil, there's no chance we can
        # load the JSON from cache so we go ahead and call as_json on the object.
        if ! reference_json
          reference_def_definition = reference_def[:definition]
          reference = reference_def_definition.is_a?(Symbol) ? object.send(reference_def_definition) : reference_def_definition.call(object)
          reference_json = reference.as_json(options) if reference
        end
        [ keys, reference_json ]
      end

      def materialize_json_references(partial_json)
        if partial_json.is_a?(Hash)
          if (_ref = partial_json.delete(:_ref))
            fetched_json = Mongoid::CachedJson.config.cache.fetch(_ref[:_key], { :force => !! Mongoid::CachedJson.config.disable_caching }) do
              materialize_cached_json(* _ref[:_materialize_cached_json])
            end
            if fetched_json
              partial_json.merge! fetched_json
            else
              # a single _ref that resolved to a nil
              return nil if partial_json.empty?
            end
          end
          partial_json.inject({}) do |h, (k, v)|
            h[k] = materialize_json_references(v)
            h
          end
        elsif partial_json.is_a?(Array)
          partial_json.map do |v|
            materialize_json_references(v)
          end
        else
          partial_json
        end
      end

    end

    def as_json(options = {})
      options ||= {}
      if options[:properties] and ! self.all_json_properties.member?(options[:properties])
        raise ArgumentError.new("Unknown properties option: #{options[:properties]}")
      end
      # partial, unmaterialized JSON
      keys, partial_json = self.class.materialize_json({
        :properties => :short, :is_top_level_json => true, :version => Mongoid::CachedJson.config.default_version
      }.merge(options), { :object => self })
      self.class.materialize_json_references(partial_json)
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
