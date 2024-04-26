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
end
