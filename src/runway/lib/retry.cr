require "retriable"

module Retry
  # This method should be called as early as possible in application startup
  # It sets up the retriable shard
  # Should the number of retries be reached without success, the last exception will be raised
  # :param log: the logger to use for retriable logging
  def self.setup!(log : Log)
    do_this_on_each_retry = ->(ex : Exception, attempt : Int32, elapsed_time : Time::Span, next_interval : Time::Span) do
      log.warn { "[attempt ##{attempt}] #{ex.class} - #{ex.message} - attempt in #{elapsed_time} seconds and #{next_interval} seconds until the next retry" }
      log.debug { "[attempt ##{attempt}] #{ex.class} - backtrace: #{ex.backtrace.join("\n")}" }
    end

    # ###### retriable configuration #######
    # All defaults available here:
    # https://github.com/Sija/retriable.cr/blob/b422892055d0b8954bb4cffeb443421eae50518f/README.md?plain=1#L55-L72
    Retriable.configure do |settings|
      settings.on_retry = do_this_on_each_retry
      settings.max_attempts = 5
      settings.max_elapsed_time = 15.minutes
      settings.max_interval = 1.minute
      settings.base_interval = 1.second
      settings.multiplier = 1.5
      settings.rand_factor = 0.5
      settings.backoff = true
      settings.random = Random::DEFAULT
    end
  end
end
