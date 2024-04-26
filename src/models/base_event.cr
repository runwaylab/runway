abstract class BaseEvent
  def initialize(log : Log, event : Event)
    @log = log
    @event = event
  end

  abstract def handle_event

  abstract def check_for_event
end

module EventRegistry
  @@events = {} of String => BaseEvent.class

  def self.register_event(event_type : String, event_class : BaseEvent.class)
    @@events[event_type] = event_class
  end

  def self.create_event(event_type : String, event_config : EventConfig) : BaseEvent
    event_class = @@events[event_type]?
    raise "Unknown event type: #{event_type}" unless event_class
    event_class.new(event_config)
  end
end
