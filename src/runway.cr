require "tasker"
require "./lib/common"
require "./lib/time"
require "./models/project"

module Runway
  def self.start(log, config)
    log.info { Emoji.emojize(":airplane: starting runway") }

    config.projects.each do |project_config|
      log.info { Emoji.emojize(":package: starting project #{project_config.name}") }

      project = Project.new(log, project_config)

      project_config.events.each do |event_config|
        if Runway::Common.is_cron?(event_config.schedule.interval)
          log.info { Emoji.emojize(":clock1: scheduling event with cron schedule #{event_config.schedule.interval}") }
          Tasker.cron(event_config.schedule.interval, Runway::TimeHelpers.timezone(event_config.schedule.timezone)) do
            project.check_for_event(event_config)
          end
        else
          log.info { Emoji.emojize(":clock1: scheduling event with interval #{event_config.schedule.interval}") }
          Tasker.every(Runway::TimeHelpers.interval(event_config.schedule.interval)) do
            project.check_for_event(event_config)
          end
        end
      end
    end

    # keep the service running forever
    sleep
  end
end
