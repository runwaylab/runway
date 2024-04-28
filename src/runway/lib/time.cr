module Runway
  module TimeHelpers
    # Constructs a Time::Span object from an interval pattern.
    #
    # @param interval [String] The interval pattern to construct the Time::Span object from.
    #   Example string: "1m" for 1 minute.
    #   Intervals must be in the format of a number followed by a unit of time (ms, s, m) and be whole numbers.
    # @return [Time::Span] The Time::Span object for the interval pattern.
    protected def self.interval(interval : String) : Time::Span
      interval_regex = /^(\d+)(ms|s|m)$/
      match = interval_regex.match(interval)

      raise "Invalid interval pattern: #{interval}" if match.nil?

      interval_int : Int32 = match[1].to_i
      unit : String = match[2]

      case unit
      when "ms" then interval_int.milliseconds
      when "s"  then interval_int.seconds
      when "m"  then interval_int.minutes
      else           raise "Invalid interval unit: #{unit}"
      end
    end

    # Gets the timezone for a schedule.
    #
    # @param timezone [String, nil] The timezone to use for the schedule, or `nil` for UTC.
    #   Example string: "America/New_York".
    # @return [Time::Location] The Time::Location object for the timezone.
    def self.timezone(timezone : String?) : Time::Location
      return Time::Location.load("UTC") if timezone.nil?

      return Time::Location.load(timezone)
    end
  end
end
