# encoding: utf-8
module Mongoid
  module CachedJson
    extend ActiveSupport::Concern
  
    included do
      class_attribute :all_json_properties
      class_attribute :cached_json_field_defs
      class_attribute :cached_json_reference_defs
      class_attribute :hide_as_child_json_when
      before_save :expire_cached_json
    end
  
    module ClassMethods
    
      # Define JSON fields for a class.
      #
      # @param [ hash ] defs JSON field definition.
      #
      # @since 1.0
      def json_fields(defs)
        json_fields_for(:default, defs)
      end

      # Define JSON fields for a class at a given version.
      #
      # @param [ ary ] versions Version or versions.
      # @param [ hash ] defs JSON field definition.
      #
      # @since 1.1
      def json_fields_for(versions, defs)
        self.hide_as_child_json_when ||= {}
        self.all_json_properties ||= {}
        self.cached_json_field_defs ||= {}
        self.cached_json_reference_defs ||= {}
        json_hide_as_child_json_when = defs.delete(:hide_as_child_json_when)
        versions = Array(versions)
        versions.each do |version|
          self.hide_as_child_json_when[version] = json_hide_as_child_json_when || lambda { |a| false }
          self.all_json_properties[version] = [:short, :public, :all]
          self.cached_json_field_defs[version] = {}
          self.cached_json_reference_defs[version] = {}
          cached_json_defs = Hash[defs.map { |k,v| [k, { :type => :callable, :properties => :short, :definition => k }.merge(v)] }]
          self.all_json_properties[version].each_with_index do |property, i|            
            self.cached_json_field_defs[version][property] = Hash[cached_json_defs.find_all do |field, definition|
              self.all_json_properties[version].find_index(definition[:properties]) <= i and definition[:type] == :callable
            end]                      
            self.cached_json_reference_defs[version][property] = Hash[cached_json_defs.find_all do |field, definition|
              self.all_json_properties[version].find_index(definition[:properties]) <= i and definition[:type] == :reference	
            end]
            # If the field is a reference and is just specified as a symbol, reflect on it to get metadata
            self.cached_json_reference_defs[version][property].to_a.each do |field, definition|
              if definition[:definition].is_a?(Symbol)
                self.cached_json_reference_defs[version][property][field][:metadata] = self.reflect_on_association(definition[:definition])
              end
            end            
          end
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
        version = options[:version]
        is_top_level_json = options[:is_top_level_json] || false
        if object_def[:object]
          object_reference = object_def[:object]
          clazz, id = object_def[:object].class, object_def[:object].id
        else
          object_reference = nil
          clazz, id = object_def[:clazz], object_def[:id]
        end
        version = clazz.json_version(version)
        json = Mongoid::CachedJson.config.cache.fetch(self.cached_json_key(options, clazz, id), { :force => !! Mongoid::CachedJson.config.disable_caching }) do
          object_reference = clazz.where({ :_id => id }).first if !object_reference
          if !object_reference or (!is_top_level_json and options[:properties] != :all and clazz.hide_as_child_json_when[version].call(object_reference))
            nil
          else
            Hash[clazz.cached_json_field_defs[version][options[:properties]].map do |field, definition|
              json_value = (definition[:definition].is_a?(Symbol) ? object_reference.send(definition[:definition]) : definition[:definition].call(object_reference))
              Mongoid::CachedJson.config.transform.each do |t|
                json_value = t.call(field, definition, json_value)
              end
              [field, json_value]
            end]
          end
        end
        reference_defs = clazz.cached_json_reference_defs[version][options[:properties]]
        if ! reference_defs.empty?
          object_reference = clazz.where({ :_id => id }).first if ! object_reference
          if !object_reference or (!is_top_level_json and options[:properties] != :all and clazz.hide_as_child_json_when[version].call(object_reference))
            nil
          else
            json = json.merge(Hash[reference_defs.map do |field, definition|
              json_properties_type = (options[:properties] == :all) ? :all : :short
              [field, clazz.resolve_json_reference(options.merge({ :properties => json_properties_type, :is_top_level_json => false}), object_reference, field, definition)]
            end])
          end
        end
        json
      end
  
      # Cache key.
      def cached_json_key(options, cached_class, cached_id)
        "as_json/#{options[:version]}/#{cached_class}/#{cached_id}/#{options[:properties]}/#{!!options[:is_top_level_json]}"
      end
  
      # If the reference is a symbol, we may be lucky and be able to figure out the as_json
      # representation by the (class, id) pair definition of the reference. That is, we may
      # be able to load the as_json representation from the cache without even getting the
      # model from the database and materializing it through Mongoid. We'll try to do this first.
      def resolve_json_reference(options, object, field, reference_def)
        reference_json = nil
        if reference_def[:metadata]
          clazz = reference_def[:metadata].class_name.constantize
          key = reference_def[:metadata].key.to_sym
          if reference_def[:metadata].relation == Mongoid::Relations::Referenced::ManyToMany
            reference_json = object.send(key).map do |id|
              materialize_json(options, { :clazz => clazz, :id => id })
            end.compact
          elsif reference_def[:metadata].relation == Mongoid::Relations::Referenced::In
            reference_json = materialize_json(options, { :clazz => clazz, :id => object.send(key) })
          end
        end
        # If we get to this point and reference_json is still nil, there's no chance we can
        # load the JSON from cache so we go ahead and call as_json on the object.
        if !reference_json
          reference = reference_def[:definition].is_a?(Symbol) ? object.send(reference_def[:definition]) : reference_def[:definition].call(object)
          reference_json = reference.as_json(options) if reference
        end
        reference_json
      end
      
      # Find the appropriate default version for the JSON to return.
      #
      # @param [ version ] version Requested version.
      #
      # @since 1.1
      def json_version(version)
        version ||= Mongoid::CachedJson.config.default_version
        raise ArgumentError.new("Missing version") unless version
        version = self.all_json_properties.keys.sort_by{ |key| key.to_s }.first if version == :default and ! self.all_json_properties.has_key?(version)
        raise ArgumentError.new("Invalid version: #{version} in #{self.name}") unless self.all_json_properties.has_key?(version)
        version
      end
      
    end
  
    # Return a JSON representation of an object.
    #
    # @param [ hash ] options Options, including :version and :properties.
    #
    # @since 1.0
    def as_json(options = { :version => :default, :properties => :short })
      version = self.class.json_version(options[:version])
      raise ArgumentError.new("Missing options[:properties]") if (options.nil? || options[:properties].nil?)
      raise ArgumentError.new("Unknown properties option: #{options[:properties]}") if !self.all_json_properties[version].member?(options[:properties])
      self.class.materialize_json({ :version => version, :is_top_level_json => true}.merge(options), { :object => self })
    end
  
    # Expire all JSON entries for this class.
    def expire_cached_json
      self.all_json_properties.each_pair do |version, all_properties|
        all_properties.each do |properties|
          [true, false].each do |is_top_level_json|
            Mongoid::CachedJson.config.cache.delete(self.class.cached_json_key({:version => version, :properties => properties, :is_top_level_json => is_top_level_json}, self.class, self.id))
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
