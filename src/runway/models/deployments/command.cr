require "../base_deployment"

# This deployment type runs a command on the local machine (where runway is running) or a remote server (via SSH)
# The actualy DeploymentConfig setup for the related project determines the command to run
class CommandDeployment < BaseDeployment
  DeploymentRegistry.register_deployment("command", self)

  def initialize(log : Log, deployment_config : DeploymentConfig)
    super(log, deployment_config)
  end

  def deploy(payload : Payload) : Payload
    @log.debug { "received a deploy() request" }
    payload.success = true
    return payload
  end
end
