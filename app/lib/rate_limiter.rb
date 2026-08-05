# Simple fixed-window rate limiter with a pluggable store.
# Used to protect authentication endpoints from brute force.
class RateLimiter
  # In-memory store suitable for single-process deployments.
  class RailsCacheStore
    def initialize(cache: Rails.cache)
      @cache = cache
    end

    def increment(key, window)
      count_key = "jachegai:rate:count:#{key}"
      started_key = "jachegai:rate:started:#{key}"
      count = @cache.increment(count_key, 1, expires_in: window)
      started = @cache.read(started_key)
      unless started
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @cache.write(started_key, started, expires_in: window)
      end
      [ count, started ]
    end

    def read(key, window)
      count_key = "jachegai:rate:count:#{key}"
      started_key = "jachegai:rate:started:#{key}"
      count = @cache.read(count_key)
      started = @cache.read(started_key)
      return [ nil, nil ] unless count && started
      return [ nil, nil ] if started + window <= Process.clock_gettime(Process::CLOCK_MONOTONIC)

      [ count, started ]
    end

    def reset
      # Namespaced cache entries expire naturally. Tests may use a cache that
      # exposes clear; production stores must not be globally cleared.
      @cache.clear if @cache.respond_to?(:clear)
    end
  end

  class MemoryStore
    def initialize
      @entries = {}
      @mutex = Mutex.new
    end

    # Increment counter for key within window. Returns [count, window_started_at].
    def increment(key, window)
      now = monotonic
      @mutex.synchronize do
        entry = @entries[key]
        if entry.nil? || entry[:started] + window <= now
          @entries[key] = { count: 1, started: now }
        else
          entry[:count] += 1
        end
        @entries[key].values_at(:count, :started)
      end
    end

    # Read current count without incrementing. Returns [count, started_at] or [nil, nil].
    def read(key, window)
      now = monotonic
      @mutex.synchronize do
        entry = @entries[key]
        return [ nil, nil ] if entry.nil? || entry[:started] + window <= now

        entry.values_at(:count, :started)
      end
    end

    def reset
      @mutex.synchronize { @entries.clear }
    end

    private

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end

  attr_reader :limit, :window, :store

  def initialize(store:, limit:, window:)
    @store = store
    @limit = limit
    @window = window
  end

  def allowed?(key)
    count, = @store.increment(key, @window)
    count <= @limit
  end

  def status(key)
    count, = @store.read(key, @window)
    remaining = count.nil? ? @limit : [ @limit - count, 0 ].max
    {
      limit: @limit,
      remaining: remaining,
      reset_at: Time.current + @window
    }
  end
end
