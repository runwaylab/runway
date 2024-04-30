require "./config"
require "./deployment_payload"

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

  # Checks for the event.
  # Subclasses must implement this method.
  # In general, checking for an event means polling a source (e.g. GitHub) for new events.
  # This could also mean checking for a new release, an updated commit, etc.
  # All event types must have a Payload object as their return type
  # Example: `return Payload.new(ship_it: true)` where ship_it is a boolean and indicates if a deployment should be triggered from the event or not
  # Note: The `ship_it` field is important throughout the codebase and should be set to `true` if a deployment should be triggered, and `false` otherwise
  # After setting this value, it can be accessed with `payload.ship_it?` where it will return a boolean
  abstract def check_for_event : Payload
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
  # @param event_config [Event] The configuration for the event.
  # @return [BaseEvent] The created event instance.
  # @raise [RuntimeError] If the event type is unknown.
  def self.create_event(event_type : String, event_config : Event, log : Log) : BaseEvent
    event_class = @@events[event_type]?
    raise "Unknown event type: #{event_type}" unless event_class
    event_class.new(log, event_config)
  end
end
