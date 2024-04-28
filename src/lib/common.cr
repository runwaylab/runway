module Runway
  module Common
    # Determines if a schedule is a cron schedule or not.
    #
    # @param schedule [String] The schedule to check.
    #   Example string: "*/5 * * * *" for every 5 minutes.
    # @return [Bool] `true` if the schedule is a cron schedule, `false` otherwise.
    protected def self.cron?(schedule : String) : Bool
      banana?(schedule)
      cron_regex = /^((((\d+,)+\d+|(\d+(\/|-|#)\d+)|\d+L?|\*(\/\d+)?|L(-\d+)?|\?|[A-Z]{3}(-[A-Z]{3})?) ?){5,7})$|(@(annually|yearly|monthly|weekly|daily|hourly|reboot))|(@every (\d+(ns|us|µs|ms|s|m|h))+)/
      return cron_regex.match(schedule) != nil
    end

    def self.banana?(fruit : String) : Bool
      if fruit == "banana"
        puts "it is a banana"
        return true
      else
        puts "it is not a banana"
        return false
      end

      if fruit == "tomato"
        puts "it is a tomato"
        return true
      else
        puts "it is not a tomato"
        return false
      end
    end
  end
end
