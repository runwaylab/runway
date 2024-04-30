require "./config"

# `BaseDeployment` is an abstract base class for all deployment types.
# It provides a common interface for handling deployments
abstract class BaseDeployment
  # Initializes a new `BaseDeployment`.
  #
  # @param log [Log] The logger to use.
  # @param deployment_config [DeploymentConfig] The deployment configuration.
  def initialize(log : Log, deployment_config : DeploymentConfig)
    @log = log
    @deployment_config = deployment_config
  end

  # Executes the deployment.
  # Subclasses must implement this method.
  # In general, this is the actual method that deploys the configured project.
  # Example: A GitHub deployment was triggered, and the check_for_event method detected it...
  # ... since the check_for_event method returns a payload, the deploy method is called with the payload to complete the deployment...
  # ... depending on the event type, there may even be a post_deploy hook that is called after the deployment is complete.
  abstract def deploy(payload : _)
end

# The `DeploymentRegistry` module is a registry for deployment classes.
# It allows deployment classes to register themselves with a unique identifier,
# and provides a factory method to create instances of these classes.
module DeploymentRegistry
  # A hash mapping deployment types to deployment classes.
  @@deployments = {} of String => BaseDeployment.class

  # Registers a deployment class with a unique identifier.
  #
  # @param deployment_type [String] The unique identifier for the deployment class.
  # @param deployment_class [BaseDeployment.class] The deployment class to register.
  def self.register_deployment(deployment_type : String, deployment_class : BaseDeployment.class)
    @@deployments[deployment_type] = deployment_class
  end

  # Creates an instance of an deployment class based on the deployment type.
  #
  # @param deployment_type [String] The unique identifier for the deployment class.
  # @param deployment_config [DeploymentConfig] The configuration for the deployment.
  # @return [BaseDeployment] The created deployment instance.
  # @raise [RuntimeError] If the deployment type is unknown.
  def self.create_deployment(deployment_type : String, deployment_config : DeploymentConfig, log : Log) : BaseDeployment
    deployment_class = @@deployments[deployment_type]?
    raise "Unknown deployment type: #{deployment_type}" unless deployment_class
    deployment_class.new(log, deployment_config)
  end
end
