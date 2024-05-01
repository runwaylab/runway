require "process"
require "../base_deployment"

# This deployment type runs a command on the local machine (where runway is running) or a remote server (via SSH)
# The actualy DeploymentConfig setup for the related project determines the command to run
class CommandDeployment < BaseDeployment
  DeploymentRegistry.register_deployment("command", self)

  @timeout : Int32
  @entrypoint : String
  @cmd : Array(String)
  @path : String
  @location : String

  def initialize(log : Log, deployment_config : DeploymentConfig)
    super(log, deployment_config)
    @timeout = deployment_config.timeout || 300
    @entrypoint = deployment_config.entrypoint.not_nil!
    @cmd = deployment_config.cmd || [] of String
    @path = deployment_config.path.not_nil!
    @location = deployment_config.location.not_nil!
  end

  def deploy(payload : Payload) : Payload
    @log.debug { "received a deploy() request for #{@deployment_config.type}" }

    # execute the command on the local system if the location is local
    cmd = Cmd.new(@entrypoint, cmd: @cmd, directory: @path, timeout: @timeout, log: @log)
    cmd.run

    @log.debug { "status: #{cmd.status}, stdout: #{cmd.stdout}, stderr: #{cmd.stderr} - success: #{cmd.success?}" }

    payload.success = cmd.success?
    return payload
  end
end

class Cmd
  getter? success : Bool?
  getter? running : Bool?
  getter status : Process::Status?
  getter stdout : String
  getter stderr : String

  def initialize(
    entrypoint : String,
    cmd : Array(String) = [] of String,
    directory : String = ".", # defaults to the current directory
    timeout : Int32 = 300,     # defaults to 5 minutes
    log : Log = nil
  )
    @entrypoint = entrypoint
    @cmd = cmd
    @directory = directory
    @timeout = timeout
    @log = log
    @stdout = ""
    @stderr = ""
    @success = nil
    @status = nil
    @running = false
  end

  def run
    @log.debug { "running command: #{@entrypoint} #{@cmd.join(" ")}" } if @log
    raise "already running command process" if @running

    @running = true
    killed = false
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    done_channel = Channel(Nil).new
    timeout_channel = Channel(Nil).new

    # start the process
    process = Process.new(
      @entrypoint,
      @cmd,
      shell: true,
      chdir: @directory,
      error: stderr,
      output: stdout
    )

    # check for the process to finish in a separate fiber
    spawn do
      status = process.wait # block until the process has finished

      done_channel.send(nil) # signal that the process has finished

      # collect info about the process after it has finished
      @status = status
      @stdout = stdout.to_s.strip
      @stderr = stderr.to_s.strip
      @success = status.success?
    end

    # start a new fiber that will send a timeout kill signal after X seconds
    spawn do
      sleep @timeout.seconds
      timeout_channel.send(nil)
    end

    # wait for the process to finish or for the timeout to occur
    select
    when done_channel.receive
      # do nothing if the process has already finished
    when timeout_channel.receive
      sleep 1.second # give the process a chance to finish (tie goes to the runner)
      unless process.terminated?
        process.try &.terminate(graceful: false) 
        @stderr = "cmd.run: command timed out after #{@timeout} seconds"
        @success = false
        killed = true
      end

      # if we make it here, something kinda unexpected happened
    end

    @log.debug { "command was killed due to exceeding the timeout" } if killed && @log

    @running = false
  rescue ex : Exception
    @stderr = ex.message.to_s
    @success = false
    @running = false
  end
end
