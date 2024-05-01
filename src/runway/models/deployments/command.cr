require "process"
require "../base_deployment"

# This deployment type runs a command on the local machine (where runway is running) or a remote server (via SSH)
# The actualy DeploymentConfig setup for the related project determines the command to run
class CommandDeployment < BaseDeployment
  DeploymentRegistry.register_deployment("command", self)

  @entrypoint : String
  @cmd : Array(String)
  @path : String
  @location : String

  def initialize(log : Log, deployment_config : DeploymentConfig)
    super(log, deployment_config)
    @entrypoint = deployment_config.entrypoint.not_nil!
    @cmd = deployment_config.cmd.not_nil!
    @path = deployment_config.path.not_nil!
    @location = deployment_config.location.not_nil!
  end

  def deploy(payload : Payload) : Payload
    @log.debug { "received a deploy() request for #{@deployment_config.type}" }

    # execute the command on the local system if the location is local
    cmd = Cmd.new(@entrypoint, cmd: @cmd, directory: @path)
    cmd.run

    @log.debug { "status: #{cmd.status}, stdout: #{cmd.stdout}, stderr: #{cmd.stderr}" }

    payload.success = cmd.success?
    return payload
  end
end

class Cmd
  getter? success : Bool?
  getter status : Process::Status?
  getter stdout : String
  getter stderr : String

  def initialize(entrypoint : String, cmd : Array(String) = [] of ElementType, directory : String = ".")
    @entrypoint = entrypoint
    @cmd = cmd
    @directory = directory
    @stdout = ""
    @stderr = ""
    @success = nil
    @status = nil
  end

  def run
    stdout = IO::Memory.new
    stderr = IO::Memory.new

    status = Process.run(
      @entrypoint,
      @cmd,
      shell: true,
      chdir: @directory,
      error: stderr,
      output: stdout
    )

    @status = status
    @stdout = @stdout.to_s.strip
    @stderr = @stderr.to_s.strip
    @success = status.success?
  end
end
