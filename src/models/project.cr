require "./base_event"
require "./events/*"

class Project
  getter events : Hash(String, BaseEvent)

  def initialize(log : Log, config : ProjectConfig)
    @config = config
    @log = log
    @name = @config.name
    @events = {} of String => BaseEvent
  end

  def check_for_event(event : Event)
    @log.info { "checking for event #{event.type} - project: #{@name}" }
    event_handler = @events[event.type]
    event_handler.check_for_event if event_handler
  end

  # this method is called at the end of the Project's class initialization
  # it is used to construct all the events that the Project class has knowledge of by looking
  # at the project's configuration
  def construct_event_knowledge!
    @config.events.each do |event_config|
      event = EventRegistry.create_event(event_config.type, event_config)
      @events[event_config.type] = event
    end
  end
end
