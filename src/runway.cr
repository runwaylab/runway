require "tasker"

module Runway
  def self.start(log, config)
    log.info { Emoji.emojize(":airplane: starting runway") }
  end

  # A helper method to determine if a schedule is a cron schedule or not
  # :param schedule: The schedule to check (String)
  # :return: True if the schedule is a cron schedule, False otherwise
  protected def self.is_cron?(schedule : String) : Bool
    # regex to match a cron schedule
    cron_regex = /^((((\d+,)+\d+|(\d+(\/|-|#)\d+)|\d+L?|\*(\/\d+)?|L(-\d+)?|\?|[A-Z]{3}(-[A-Z]{3})?) ?){5,7})$|(@(annually|yearly|monthly|weekly|daily|hourly|reboot))|(@every (\d+(ns|us|µs|ms|s|m|h))+)/
    return cron_regex.match(schedule) != nil
  end
end
