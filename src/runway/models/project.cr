require "uuid"
require "./events/*"

# The `Project` class represents a project that can handle different types of events.
# It uses an `EventRegistry` to create event handlers based on the event type.
class Project
  # Provides read access to the `events` instance variable.
  # @return [Hash(String, BaseEvent)] A hash mapping event types to event handlers.
  getter events : Hash(String, BaseEvent)

  # Initializes a new `Project`.
  #
  # @param log [Log] The logger to use.
  # @param config [ProjectConfig] The configuration for the project.
  def initialize(log : Log, config : ProjectConfig)
    @config = config
    @log = log
    @name = @config.name
    @events = {} of String => BaseEvent
    hydrate_event_handlers!
  end

  # Hydrates all the event handles for the project.
  protected def hydrate_event_handlers!
    @config.events.each do |event|
      @events[event.uuid.not_nil!] = EventRegistry.create_event(event.type, event, @log)
    end
  end

  # Checks for an event and handles it if the event type is registered.
  #
  # @param event [Event] The event to check for.
  def check_for_event(event : Event)
    @log.info { Emoji.emojize(":eyes: #{@name} is checking for a #{event.type} event") }

    @events[event.uuid.not_nil!].check_for_event
  end
end
