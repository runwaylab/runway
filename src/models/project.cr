class Project
  def initialize(log : Log, config : ProjectConfig)
    @config = config
    @log = log
    @name = @config.name
  end

  def check_for_event(event : Event)
    @log.info { "checking for event #{event.type} - project: #{@name}" }
  end
end
