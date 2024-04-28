require "tasker"
require "uuid"
require "./runway/lib/common"
require "./runway/lib/time"
require "./runway/models/project"
require "./runway/models/config"
require "./version"

module Runway
  # The `Service` class is responsible for starting the Runway service.
  # It initializes the service with a logger and a configuration,
  # starts the service, and schedules events for each project in the configuration.
  ERROR_PREFIX    = ":boom: error while checking for event:"
  SCHEDULE_PREFIX = ":clock1: scheduling event with"

  class Service
    # Initializes a new `Service`.
    #
    # @param log [Log] The logger to use.
    # @param config [RunwayConfiguration] The configuration for the service.
    def initialize(log : Log, config : RunwayConfiguration)
      @log = log
      @config = config
    end

    # Starts the service.
    # It logs the start of the service, creates a `Project` for each project in the configuration,
    # schedules events for each project, and then keeps the service running until it is stopped.
    def start!
      @log.info { Emoji.emojize(":airplane: starting runway - version: v#{VERSION}") }

      @config.projects.each do |project_config|
        # assign a uuid to the project
        project_config.uuid = UUID.random.to_s

        @log.info { Emoji.emojize(":package: starting project #{project_config.name}") }

        # iterate over all the events in the project and assign uuids to them
        project_config.events.each do |event_config|
          event_config.uuid = UUID.random.to_s
        end

        project = Project.new(@log, project_config)
        schedule_events(project, project_config.events)
      end

      # keep the service running until it is stopped (e.g. by a signal or ctrl + c)
      sleep
    end

    # Schedules events for a project.
    #
    # @param project [Project] The project to schedule events for.
    # @param events [Array] The events to schedule.
    private def schedule_events(project : Project, events : Array)
      events.each do |event_config|
        schedule_event(project, event_config)
      end
    end

    # Schedules an event for a project.
    # It determines the schedule type (cron or interval) and schedules the event accordingly.
    #
    # @param project [Project] The project to schedule the event for.
    # @param event_config The configuration for the event.
    private def schedule_event(project : Project, event_config)
      interval = event_config.schedule.interval
      if Runway::Common.cron?(interval)
        @log.info { Emoji.emojize("#{SCHEDULE_PREFIX} cron schedule #{interval}") }
        Tasker.cron(interval, Runway::TimeHelpers.timezone(event_config.schedule.timezone)) do
          begin
            project.check_for_event(event_config)
          rescue error : Exception
            @log.error { Emoji.emojize("#{ERROR_PREFIX} #{error.message} - traceback: #{error.backtrace.join("\n")}") }
          end
        end
      else
        @log.info { Emoji.emojize("#{SCHEDULE_PREFIX} interval #{interval}") }
        Tasker.every(Runway::TimeHelpers.interval(interval)) do
          begin
            project.check_for_event(event_config)
          rescue error : Exception
            @log.error { Emoji.emojize("#{ERROR_PREFIX} #{error.message} - traceback: #{error.backtrace.join("\n")}") }
          end
        end
      end
    end
  end
end
