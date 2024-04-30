require "uuid"
require "./events/*"
require "./deployments/*"

# The `Project` class represents a project that can handle different types of events.
# It uses an `EventRegistry` to create event handlers based on the event type.
class Project
  # Provides read access to the `events` instance variable.
  # @return [Hash(String, BaseEvent)] A hash mapping event types to event handlers.
  getter events : Hash(String, BaseEvent)

  # Provides read access to the name of the project.
  # @return [String] The name of the project. 
  getter name : String

  @deployment : BaseDeployment

  # Initializes a new `Project`.
  #
  # @param log [Log] The logger to use.
  # @param config [ProjectConfig] The configuration for the project.
  def initialize(log : Log, config : ProjectConfig)
    @config = config
    @log = log
    @name = @config.name
    @events = {} of String => BaseEvent
    @deployment = hydrate_deployment!
    hydrate_event_handlers!
  end

  # Hydrates all the event handles for the project.
  protected def hydrate_event_handlers!
    @config.events.each do |event|
      @events[event.uuid.not_nil!] = EventRegistry.create_event(event.type, event, @log)
    end
  end

  # Hydrates the deployment configuration for the project.
  # Note: there should only be one deployment configuration per project. 
  protected def hydrate_deployment!
    DeploymentRegistry.create_deployment(@config.deployment.type, @config.deployment, @log)
  end 

  # Checks for an event and handles it if the event type is registered.
  # If the event was triggered (any return value other than `nil`), the project's deployment configuration is run.
  #
  # @param event [Event] The event to check for.
  def check_for_event(event : Event)
    @log.info { Emoji.emojize(":eyes: #{@name} is checking for a #{event.type} event") } unless Runway::QUIET

    # Check if the desired event type had a deployable event occur
    payload = @events[event.uuid.not_nil!].check_for_event

    # If the event was triggered, run the project's deployment configuration
    @deployment.deploy(payload) if payload
  end
end
