require "process"
require "ssh2"
require "../models/base_deployment"
require "../models/configs/remote_config"

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
    @path = deployment_config.path || "."
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
        @deployment_config.remote.not_nil!,
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

    @log.debug { "output: #{cmd.output}, - success: #{cmd.success?}" }

    payload.success = cmd.success?
    return payload
  end
end

class RemoteCmd
  getter? success : Bool?
  getter output : String

  def initialize(
    remote_config : RemoteConfig,
    entrypoint : String,
    cmd : Array(String) = [] of String,
    directory : String = ".", # defaults to the current directory
    timeout : Int32 = 300,    # defaults to 5 minutes
    log : Log = nil
  )
    @remote_config = remote_config
    @entrypoint = entrypoint
    @cmd = cmd
    @directory = directory
    @timeout = timeout
    @log = log
    @output = ""
    @success = nil
    @log_prefix = "remote_cmd"
  end

  def run
    # required fields
    host = @remote_config.host.not_nil!
    port = @remote_config.port || 22
    username = @remote_config.username.not_nil!
    use_ssh_agent = @remote_config.auth.not_nil! == "agent"
    use_basic_password = @remote_config.auth.not_nil! == "password"
    use_public_key = @remote_config.auth.not_nil! == "publickey"

    # optional fields (other auth methods may require them)
    password_env_var_name = @remote_config.password || "RUNWAY_REMOTE_SSH_DEPLOY_PASSWORD"
    passphrase_env_var_name = @remote_config.passphrase || "RUNWAY_REMOTE_SSH_DEPLOY_PASSPHRASE"
    password = ENV.fetch(password_env_var_name, nil)
    passphrase = ENV.fetch(passphrase_env_var_name, nil)
    success_string = @remote_config.success_string || nil

    @log.debug { "#{@log_prefix} use_ssh_agent: #{use_ssh_agent}" } if @log
    @log.debug { "#{@log_prefix} use_basic_password: #{use_basic_password}" } if @log
    @log.debug { "#{@log_prefix} use_public_key: #{use_public_key}" } if @log
    @log.debug { "#{@log_prefix} host: #{host} - port: #{port} - username: #{username}" } if @log

    result = IO::Memory.new
    IO::MultiWriter.new(result)

    Retriable.retry(on: {SSH2::SSH2Error, SSH2::SessionError, Socket::ConnectError}) do
      Retriable.retry(on: Tasker::Timeout, backoff: false) do
        Tasker.timeout(@timeout.seconds) do
          SSH2::Session.open(host, port) do |session|
            session.timeout = @timeout
            session.knownhosts.delete_if { |knownhost| knownhost.name == host }

            if use_ssh_agent
              @log.debug { "#{@log_prefix} attempting to log in with ssh-agent" } if @log
              session.login_with_agent(username)
            elsif use_public_key
              @log.debug { "#{@log_prefix} attempting to log in with public key" } if @log

              # if a passphrase_env_var_name was provided, but no passphrase was found for that variable, log a warning
              if passphrase.nil?
                @log.debug { "#{@log_prefix} no private key passphrase was provided - using an empty passphrase..." }
              end

              pub_key = @remote_config.public_key_path.not_nil!
              priv_key = @remote_config.private_key_path.not_nil!

              @log.debug { "#{@log_prefix} priv_key: #{priv_key}" } if @log
              @log.debug { "#{@log_prefix} pub_key: #{pub_key}" } if @log

              # note: make your ssh keys have 600ish permissions and the containing directory 700ish permissions
              raise "#{@log_prefix} public key file does not exist" unless File.exists?(pub_key)
              raise "#{@log_prefix} private key file does not exist" unless File.exists?(priv_key)

              session.login_with_pubkey(username, priv_key, pub_key, passphrase)
            elsif use_basic_password
              @log.debug { "#{@log_prefix} attempting to log in with a username + password" } if @log
              raise "#{@log_prefix} deployment.remote.password should point to an environment variable" if password.nil?
              session.login(username, password)
            end

            session.open_session do |channel|
              # construct the command to run
              command = ""
              if @directory == "."
                # if no directory is specified, just run the command in the current directory
                command = @entrypoint + " " + @cmd.join(" ")
              else
                raise "#{@log_prefix} custom directories are not yet supported in remote deployments"
              end

              @log.debug { "#{@log_prefix} running command: #{command}" } if @log

              channel.command(command)
              IO.copy(channel, result)
            end
          end
        end
      end
    end

    @output = result.to_s.chomp

    if success_string
      # if a success_string was provided, check for it in the output to determine if the command was successful
      @success = @output.includes?(success_string)
      @log.debug { "#{@log_prefix} success_string: #{success_string} #{@success ? "found" : "not found"} in remote_cmd output" } if @log
    else
      # if no success_string was provided, assume the command was successful (kinda dangerous)
      @log.debug { "#{@log_prefix} no deployment.remote.success_string provided - assuming command was successful" } if @log
      @success = true
    end

    return
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
