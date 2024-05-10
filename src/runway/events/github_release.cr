require "../models/base_event"
require "../services/github"

class GitHubRelease < BaseEvent
  EventRegistry.register_event("github_release", self)
  @repo : String
  @version_requirement : String
  @current_version : String?

  def initialize(log : Log, event : Event)
    super(log, event)
    @github = Runway::GitHub.new(log)
    @repo = @event.repo.not_nil!
    @version_requirement = @event.version.not_nil!
    @current_version = nil # on first run, this will be nil and will always trigger a deployment (but then it will be set)
  end

  # This method is called after the project's deployment has completed
  # @param payload [Payload] the payload object that contains the deployment status and other information
  # @return [Payload] the payload object that was passed in with possibly updated information/attributes
  def post_deploy(payload : Payload) : Payload
    @log.debug { "received a post_deploy() request for deployment.id: #{payload.id} from event.uuid: #{@event.uuid}" }
    @log.debug { "post_deploy() payload: #{payload.inspect}" } if Runway::VERBOSE

    # exit early if the payload doesn't have a run_post_deploy? attribute
    return payload unless payload.run_post_deploy? == true

    if payload.success?
      @log.info { "deployment was successful" } unless Runway::QUIET
    else
      @log.error { "deployment failed" }
    end

    return payload
  rescue error : Exception
    @log.error { "error handling deployment event: #{error.message}" }
    return payload
  end

  # Check for a GitHub release event for the specified repository
  # This method uses post_deploy hooks to log information after a deployment completes/fails
  def check_for_event : Payload
    payload = Payload.new(ship_it: false, run_post_deploy: true)

    @log.debug { "received a check_for_event() request for event.uuid: #{@event.uuid}" }
    @log.info { "checking #{@repo} for a new release" } unless Runway::QUIET

    release = @github.latest_release_tag(@repo).lchop('v')

    return payload
  end
end
