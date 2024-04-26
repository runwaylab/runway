# `BaseEvent` is an abstract base class for all event types.
# It provides a common interface for handling and checking for events.
abstract class BaseEvent
  # Initializes a new `BaseEvent`.
  #
  # @param log [Log] The logger to use.
  # @param event [Event] The event configuration.
  def initialize(log : Log, event : Event)
    @log = log
    @event = event
  end

  # Handles the event.
  # Subclasses must implement this method.
  # In general, handling an event means performing a deployment.
  # Example: A GitHub deployment was triggered, and the check_for_event method detected it...
  # ...now the handle_event method will be called to perform the deployment.
  abstract def handle_event

  # Checks for the event.
  # Subclasses must implement this method.
  # In general, checking for an event means polling a source (e.g. GitHub) for new events.
  # This could also mean checking for a new release, an updated commit, etc.
  abstract def check_for_event
end

# The `EventRegistry` module is a registry for event classes.
# It allows event classes to register themselves with a unique identifier,
# and provides a factory method to create instances of these classes.
module EventRegistry
  # A hash mapping event types to event classes.
  @@events = {} of String => BaseEvent.class

  # Registers an event class with a unique identifier.
  #
  # @param event_type [String] The unique identifier for the event class.
  # @param event_class [BaseEvent.class] The event class to register.
  def self.register_event(event_type : String, event_class : BaseEvent.class)
    @@events[event_type] = event_class
  end

  # Creates an instance of an event class based on the event type.
  #
  # @param event_type [String] The unique identifier for the event class.
  # @param event_config [EventConfig] The configuration for the event.
  # @return [BaseEvent] The created event instance.
  # @raise [RuntimeError] If the event type is unknown.
  def self.create_event(event_type : String, event_config : EventConfig) : BaseEvent
    event_class = @@events[event_type]?
    raise "Unknown event type: #{event_type}" unless event_class
    event_class.new(event_config)
  end
end
