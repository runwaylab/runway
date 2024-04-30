require "../base_deployment"

class CommandDeployment < BaseDeployment
  DeploymentRegistry.register_deployment("command", self)

  def initialize(log : Log, deployment_config : DeploymentConfig)
    super(log, deployment_config)
  end

  def deploy(payload)
    @log.debug { "received a deploy() request" }
  end
end
