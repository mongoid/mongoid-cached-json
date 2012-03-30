module CachedJsonMatchers
  class Invalidate
    def initialize(*args)
      @args = args
    end
    def matches?(proc)
      Array(@args).each do |cached_model|
        cached_model.should_receive(:expire_cached_json)
      end
      proc.call
    end
    def description
      "invalidates the API cache for a given model"
    end
    def failure_message
      "expected cache to be invalidated"
    end
    def negative_failure_message
      "expected cache not to be invalidated"
    end
  end
  def invalidate(*args)
    CachedJsonMatchers::Invalidate.new(*args)
  end
end



