require "../base_deployment"

# This deployment type runs a command on the local machine (where runway is running) or a remote server (via SSH)
class CommandDeployment < BaseDeployment
  DeploymentRegistry.register_deployment("command", self)

  def initialize(log : Log, deployment_config : DeploymentConfig)
    super(log, deployment_config)
  end

  def deploy(payload : Payload)
    @log.debug { "received a deploy() request" }
  end
end
