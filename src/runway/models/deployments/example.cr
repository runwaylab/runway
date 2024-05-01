require "../base_deployment"

# This class demonstrates how you can extend the BaseDeployment class to create a new deployment type!
# Deployment types are defined in the config file for runway. (deployment.type in the config file)
# This class defines how projects are "deployed" when a deployable "event" is detected.
#
# You should copy/paste this entire file as a starting point for creating a new deployment type
class ExampleDeployment < BaseDeployment
  DeploymentRegistry.register_deployment("example_deployment", self) # where "example_deployment" matches the deployment.type from the config file

  # This is the constructor for the class. It is required to call the super constructor with the log and event
  # After calling super, you can do any additional setup you need for your deployment type
  # See the `command.cr` file for a live example of how to use this class to run a command on a local/remote server for deployments
  def initialize(log : Log, deployment_config : DeploymentConfig)
    super(log, deployment_config) # this is required
  end

  # If `check_for_event` determines that the event should be handled, this method is then invoked to actually run the deployment...
  # ... for your project
  # This method will actually handle the event and make the deployment. For example, if you want to deploy a new release...
  # ... you might write custom code here to deploy the new release
  # @param payload - the payload object that contains the event data (see the `base_deployment.cr` file for more info on the payload object) - you should do so if you are writing a new deployment type, it can be extremely helpful
  # @return - the payload object that contains the event data (see the `base_deployment` file for more info on the payload object) 
  def deploy(payload : Payload) : Payload
    @log.info { "processing a deployment event!" }
    return payload
  end
end
