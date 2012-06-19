# encoding: utf-8
module Mongoid 
  module CachedJson 
    module Config
      extend self
      include ActiveSupport::Callbacks
  
      # Current configuration settings.
      attr_accessor :settings
      
      # Default configuration settings.
      attr_accessor :defaults
      
      @settings = {}
      @defaults = {}
  
      # Define a configuration option with a default.
      #
      # @example Define the option.
      #   Config.option(:cache, :default => nil)
      #
      # @param [ Symbol ] name The name of the configuration option.
      # @param [ Hash ] options Extras for the option.
      #
      # @option options [ Object ] :default The default value.
      def option(name, options = {})
        defaults[name] = settings[name] = options[:default]
  
        class_eval <<-RUBY
          def #{name}
            settings[#{name.inspect}]
          end
  
          def #{name}=(value)
            settings[#{name.inspect}] = value
          end
  
          def #{name}?
            #{name}
          end
        RUBY
      end
      
      # Disable caching.
      option :disable_caching, { :default => false }
      
      # Returns the default JSON version
      #
      # @example Get the default JSON version
      #   config.default_version
      #
      # @return [ Version ] The default JSON version.
      def default_version
        settings[:default_version] = :unspecified unless settings.has_key?(:default_version)
        settings[:default_version]
      end

      # Sets the default JSON version.
      #
      # @example Set the default version.
      #   config.default_version = :v2
      #
      # @return [ Version ] The newly set default version.
      def default_version=(default_version)
        settings[:default_version] = default_version
      end
      
      # Returns the default cache store, for example Rails cache or an instance of ActiveSupport::Cache::MemoryStore.
      #
      # @example Get the default cache store
      #   config.default_cache
      #
      # @return [ Cache ] The default Cache instance.
      def default_cache
        defined?(Rails) && Rails.respond_to?(:cache) ? Rails.cache : ::ActiveSupport::Cache::MemoryStore.new
      end
  
      # Returns the cache, or defaults to Rails cache when running under Rails or ActiveSupport::Cache::MemoryStore.
      #
      # @example Get the cache.
      #   config.cache
      #
      # @return [ Cache ] The configured cache or a default cache instance.
      def cache
        settings[:cache] = default_cache unless settings.has_key?(:cache)
        settings[:cache]
      end
  
      # Sets the cache to use.
      #
      # @example Set the cache.
      #   config.cache = Rails.cache
      #
      # @return [ Cache ] The newly set cache.
      def cache=(cache)
        settings[:cache] = cache
      end
  
      # Reset the configuration options to the defaults.
      #
      # @example Reset the configuration options.
      #   config.reset!
      def reset!
        settings.replace(defaults)
      end
      
      # Define a transformation on JSON data.
      #
      # @example Convert every string in materialized JSON to upper-case.
      #   config.transform do |field, value|
      #      value.upcase
      #   end
      def transform(& block)
        settings[:transform] = [] unless settings.has_key?(:transform)
        settings[:transform] << block if block_given?
        settings[:transform]
      end
  
    end
  end
end
