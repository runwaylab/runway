require "process"
require "ssh2"
require "../models/base_deployment"

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
    if @location == "local"
      cmd = LocalCmd.new(
        @entrypoint,
        cmd: @cmd,
        directory: @path,
        timeout: @timeout,
        log: @log
      )
    elsif @location == "remote"
      cmd = RemoteCmd.new(
        @entrypoint,
        cmd: @cmd,
        directory: @path,
        timeout: @timeout,
        log: @log
      )
    else
      raise "unsupported location: #{@location} - must be 'local' or 'remote'"
    end

    cmd.run

    # @log.debug { "output: #{cmd.output}, - success: #{cmd.success?}" }

    payload.success = cmd.success?
    return payload
  end
end

class RemoteCmd
  getter? success : Bool?
  getter output : String

  def initialize(
    entrypoint : String,
    cmd : Array(String) = [] of String,
    directory : String = ".", # defaults to the current directory
    timeout : Int32 = 300,    # defaults to 5 minutes
    log : Log = nil
  )
    @entrypoint = entrypoint
    @cmd = cmd
    @directory = directory
    @timeout = timeout
    @log = log
    @output = ""
    @success = nil
  end

  def run
    @log.debug { "running command: #{@entrypoint} #{@cmd.join(" ")}" } if @log

    host = "localhost"
    pub_key = "acceptance/ssh_server/keys/public/id_rsa.pub"
    priv_key = "acceptance/ssh_server/keys/private/id_rsa"
    use_ssh_agent = false

    result = IO::Memory.new
    IO::MultiWriter.new(result)

    Retriable.retry(on: {SSH2::SSH2Error, SSH2::SessionError, Socket::ConnectError}) do
      Retriable.retry(on: Tasker::Timeout, backoff: false) do
        Tasker.timeout(5.seconds) do
          SSH2::Session.open(host, 2222) do |session|
            session.timeout = 5000
            session.knownhosts.delete_if { |knownhost| knownhost.name == host }

            if use_ssh_agent
              session.login_with_agent("root")
            else
              session.login_with_pubkey("root", priv_key, pub_key)
            end

            session.open_session do |channel|
              channel.command("cd /app/logs && ls -lah")
              IO.copy(channel, result)
            end
          end
        end
      end
    end

    @output = result.to_s.chomp
    @success = true
  rescue ex : Exception
    @output = ex.message.to_s
    @success = false
  end
end

class LocalCmd
  getter? success : Bool?
  getter output : String

  @status : Process::Status?

  def initialize(
    entrypoint : String,
    cmd : Array(String) = [] of String,
    directory : String = ".", # defaults to the current directory
    timeout : Int32 = 300,    # defaults to 5 minutes
    log : Log = nil
  )
    @entrypoint = entrypoint
    @cmd = cmd
    @directory = directory
    @timeout = timeout
    @log = log
    @stdout = ""
    @stderr = ""
    @output = ""
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
      # set the value of output depending on the success of the process
      @output = @success ? @stdout : @stderr 
    when timeout_channel.receive
      sleep 1.second # give the process a chance to finish (tie goes to the runner)
      unless process.terminated?
        process.try &.terminate(graceful: false)
        @stderr = "cmd.run: command timed out after #{@timeout} seconds"
        @output = @stderr
        @success = false
        killed = true
      end

      # if we make it here, something kinda unexpected happened
    end

    @log.debug { "command was killed due to exceeding the timeout" } if killed && @log

    @running = false
  rescue ex : Exception
    @stderr = ex.message.to_s
    @output = @stderr
    @success = false
    @running = false
  end
end
