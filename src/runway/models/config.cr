require "yaml"
require "./configs/*"

# The `RunwayConfiguration` class represents the configuration for the Runway service.
# It includes an array of `ProjectConfig` objects, each representing a project's configuration.
#
# @see https://crystal-lang.org/api/1.12.1/YAML/Serializable.html
class RunwayConfiguration
  include YAML::Serializable

  # @return [Array(ProjectConfig)] The array of project configurations.
  property projects : Array(ProjectConfig)
end

# The `ProjectConfig` class represents the configuration for a project.
# A project is a collection of events that trigger deployments and are run on a schedule.
# It includes properties for the project's name, type, location, path, and events.
class ProjectConfig
  include YAML::Serializable

  # @return [String] The name of the project.
  property name : String

  # @return [Array(Event)] The array of events for the project.
  property events : Array(Event)

  property deployment : DeploymentConfig

  # @return [String, nil] The UUID for the project, or `nil` if not specified.
  # The application will generate a UUID for the event if one is not provided.
  property uuid : String?
end

class DeploymentConfig
  include YAML::Serializable

  # @return [String] The type of the project.
  property type : String

  # @return [String] The location of the project.
  property location : String?

  # @return [String] The path of the project.
  property path : String?

  # @return [String] The command/entrypoint to run for the project.
  property entrypoint : String?

  # @return [Array(String)] The arguments to pass to the command.
  property cmd : Array(String)?

  # @return [Int32, nil] The timeout for the command, or `nil` if not specified.
  property timeout : Int32?

  # @return [RemoteConfig, nil] The remote configuration for the deployment, or `nil` if not specified.
  property remote : RemoteConfig?
end

# The `Event` class represents an event that triggers a deployment for a project.
# It includes properties for the event's type, repository, environment, and schedule.
class Event
  include YAML::Serializable

  # @return [String] The type of the event.
  property type : String

  # @return [String, nil] The repository for the event, or `nil` if not specified.
  property repo : String?

  # @return [String, nil] The environment for the event, or `nil` if not specified.
  property environment : String?

  # @return [Schedule] The schedule for the event.
  property schedule : Schedule

  # @return [String, nil] The UUID for the event, or `nil` if not specified.
  # The application will generate a UUID for the event if one is not provided.
  property uuid : String?

  # @return [Int32, nil] The deployment filter for the event, or `nil` if not specified.
  # Deployment filters are used to filter out deployments to X number of most recent deployments
  # This helps save on API requests and prevent unnecessary deployments
  # This property is specific to the github_deployment event type
  property deployment_filter : Int32?

  # @return [String, nil] A path for a file, or `nil` if not specified. Used by a few event types.
  property path : String?

  # @return [Bool, nil] A flag to enable property cleanup, or `nil` if not specified. Used by a few event types.
  property cleanup : Bool?
end

# The `Schedule` class represents the schedule for an event.
# It includes properties for the schedule's interval and timezone.
class Schedule
  include YAML::Serializable

  # @return [String] The interval for the schedule.
  property interval : String

  # @return [String, nil] The timezone for the schedule, or `nil` if not specified.
  property timezone : String?
end
