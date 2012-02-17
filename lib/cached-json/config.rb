module CachedJson #:nodoc
  module Config
    extend self
    include ActiveModel::Observing

    attr_accessor :settings, :defaults
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

    # Returns the default cache store, which is either a Rails logger of stdout logger
    #
    # @example Get the default cache store
    #   config.default_cache
    #
    # @return [ Cache ] The default Cache instance.
    def default_cache
      defined?(Rails) && Rails.respond_to?(:cache) ? Rails.cache : ::ActiveSupport::Cache::MemoryStore.new
    end

    # Returns the cache, or defaults to Rails cache or ActiveSupport::Cache::MemoryStore logger.
    #
    # @example Get the cache.
    #   config.cache
    #
    # @return [ Cache ] The configured cache or a default cache instance.
    def cache
      @cache = default_cache unless defined?(@cache)
      @cache
    end

    # Sets the cache to use.
    #
    # @example Set the cache.
    #   config.cache = Rails.cache
    #
    # @return [ Cache ] The newly set cache.
    def cache=(cache)
      @cache = cache
    end

    # Reset the configuration options to the defaults.
    #
    # @example Reset the configuration options.
    #   config.reset
    def reset
      settings.replace(defaults)
    end

  end
end
