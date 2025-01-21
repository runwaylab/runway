require "../models/base_event"
require "../models/branch_deploy_payload"
require "../services/github"

class GitHubDeployment < BaseEvent
  EventRegistry.register_event("github_deployment", self)
  @deployment_filter : Int32
  @repo : String

  def initialize(log : Log, event : Event)
    super(log, event)
    @github = Runway::GitHub.new(log)
    @deployment_filter = @event.deployment_filter.try(&.to_i) || 1
    @repo = @event.repo.not_nil!
    @success = "success"
    @failure = "failure"
    @branch_deploy_enabled = @event.branch_deploy.try(&.enabled) || false
  end

  # This method is called after the project's deployment has completed
  # It will create a GitHub deployment status that reflects the deployment's success or failure
  # The deployment status to use comes from the Payload.status attribute (success or failure)
  # @param payload [Payload] the payload object that contains the deployment status and other information
  # @return [Payload] the payload object that was passed in with possibly updated information/attributes
  def post_deploy(payload : Payload) : Payload
    @log.debug { "received a post_deploy() request for deployment.id: #{payload.id} from event.uuid: #{@event.uuid}" }
    @log.debug { "post_deploy() payload: #{payload.inspect}" } if Runway::VERBOSE

    # exit early if the payload doesn't have a run_post_deploy? attribute
    return payload unless payload.run_post_deploy? == true

    if payload.success?
      payload.status = @success
    else
      payload.status = @failure
    end

    @log.info { Emoji.emojize(":hammer_and_wrench:  handling a deployment event for #{@repo} in the #{@event.environment} environment") } unless Runway::QUIET

    deployment_id = payload.id.to_s.to_i64.not_nil!
    status = payload.status.not_nil!

    # create a deployment status
    result = @github.create_deployment_status(@repo, deployment_id, status)

    @log.debug { "deployment status result: #{result.to_pretty_json}" } if Runway::VERBOSE

    raise "Unexpected deployment status result" unless result.state == @success

    # logs about the deployment status
    @log.info { Emoji.emojize(":white_check_mark: successfully completed deployment for #{@repo} in the #{@event.environment} environment") } if status == @success unless Runway::QUIET
    @log.error { Emoji.emojize(":x: failed to complete deployment for #{@repo} in the #{@event.environment} environment") } if status != @success

    return payload
  rescue error : Exception
    @log.error { "error handling deployment event: #{error.message} - attempting to set a 'failure' statue on the deployment" }
    result = @github.create_deployment_status(@repo, payload.id.to_s.to_i64.not_nil!, @failure)
    @log.debug { "deployment status result (on error): #{result.to_pretty_json}" }
    return payload
  end

  # Check for a GitHub deployment event in the specified environment
  # This method uses post_deploy hooks to create a deployment status for the deployment after a deployment completes/fails
  def check_for_event : Payload
    payload = Payload.new(ship_it: false, run_post_deploy: true)

    @log.debug { "received a check_for_event() request for event.uuid: #{@event.uuid}" }
    @log.info { "checking #{@repo} for a #{@event.environment} deployment event" } unless Runway::QUIET
    deployments = @github.deployments(@repo, @event.environment.not_nil!)

    @log.debug { "GitHubDeployment -> check_for_event() deployments: #{deployments}" } if Runway::VERBOSE

    deployments = parse_and_filter_deployments(deployments)

    detected_deployment = find_in_progress_deployment(deployments)

    # exit early if we didn't find a deployment in_progress
    return payload unless detected_deployment

    payload = set_payload_attributes(payload, detected_deployment)
    log_payload_warnings(payload)

    return payload
  end

  # filter deployments by environment
  # this should already have been done by the GitHub API, but we'll do it again out of extra caution
  # @param deployments [JSON::Any] the deployments to filter
  # @return [Array] the filtered deployments
  protected def filter_deployments(deployments : Array(Octokit::Models::Deployment)) : Array(Octokit::Models::Deployment)
    deployments.select do |deployment|
      deployment.environment == @event.environment
    end
  end

  # sort deployments by created_at date with the most recent first
  # uses the deployment_filter attribute to only grab the X most recent deployments
  # @param deployments [Array] the deployments to sort
  # @return [Array] the sorted deployments
  protected def sort_deployments(deployments : Array(Octokit::Models::Deployment)) : Array(Octokit::Models::Deployment)
    deployments = deployments.sort_by(&.created_at).reverse!

    # only grab the X most recent deployments (based on event.filters.deployments)
    return deployments.first(@deployment_filter)
  end

  # A helper method to find the most recent deployment with an "in_progress" status and return it (if it exists)
  # @param deployments [Array] the deployments to search through
  # @return [JSON::Any] the deployment with an "in_progress" status or nil if it doesn't exist
  protected def find_in_progress_deployment(deployments : Array) : Octokit::Models::Deployment | Nil
    # loop through all filtered deployments and get their deployment statuses
    # the first deployment to have an "in_progress" status will be the one we're looking for
    # however, the "in_progress" status must be the most recent status for the deployment or we'll ignore it
    deployments.each do |deployment|
      deployment_id = deployment.id.to_i32
      statuses = @github.list_deployment_statuses(@event.repo.not_nil!, deployment_id, per_page: 100)
      statuses = statuses.records

      # sort statuses by created_at date with the most recent first
      statuses = statuses.sort_by(&.created_at).reverse!

      # if the most recent status is "in_progress", we have our deployment
      if statuses.first.state == "in_progress"
        @log.debug { "found an in_progress deployment for #{@repo} in the #{@event.environment} environment" }
        return deployment
      end
    end

    # if we've reached this point, we didn't find a deployment in_progress
    return nil
  end

  # set the payload attributes based on the detected deployment
  # @param payload [Payload] the payload object to set attributes on
  # @param detected_deployment [Octokit::Models::Deployment] the detected deployment to get attributes from
  # @return [Payload] the payload object with attributes set
  protected def set_payload_attributes(payload : Payload, detected_deployment : Octokit::Models::Deployment) : Payload
    payload.id = detected_deployment.id.to_s
    payload.environment = detected_deployment.environment
    payload.created_at = detected_deployment.created_at.to_s
    payload.updated_at = detected_deployment.updated_at.to_s
    payload.description = detected_deployment.description
    payload.user = detected_deployment.creator.login
    payload.sha = detected_deployment.sha
    payload.ref = detected_deployment.ref
    payload.branch_deploy_payload = parse_github_branch_deploy_payload(detected_deployment)
    payload.status = "in_progress"
    payload.ship_it = true
    return payload
  end

  # set the branch_deploy_payload attribute if it exists
  # https://github.com/github/branch-deploy/blob/f9cc91d1f3b53149b3abcb582f2844993cd9277d/docs/deployment-payload.md
  protected def parse_github_branch_deploy_payload(deployment : Octokit::Models::Deployment) : BranchDeployPayload | Nil
    unless @branch_deploy_enabled
      @log.debug { "branch_deploy is not enabled for #{@repo} - skipping branch_deploy payload hydration" }
      return nil
    end

    if deployment.payload.nil?
      @log.debug { "payload is nil for #{@repo} - skipping branch_deploy payload hydration" }
      return nil
    end

    return BranchDeployPayload.from_json(deployment.payload.to_s)
  end

  # logging for debugging purposes
  # @param payload [Payload] the payload to log warnings for
  protected def log_payload_warnings(payload : Payload) : Nil
    @log.warn { Emoji.emojize(":warning: deployment sha is missing from the deployment payload") } if payload.sha.nil?
    @log.debug { "in_progress deployment sha for #{@repo}: #{payload.sha}" }
    @log.warn { Emoji.emojize(":warning: deployment ref is missing from the deployment payload") } if payload.ref.nil?
    @log.debug { "in_progress deployment ref for #{@repo}: #{payload.ref}" }
  end

  # A helper method to parse and filter deployments
  # It parses the raw JSON response and filters deployments by environment
  # It then sorts the deployments as well
  # @param deployments [String] the deployments raw JSON response
  # @return [Array] the parsed, filtered, and sorted deployments
  protected def parse_and_filter_deployments(deployments : Octokit::Connection::Paginator(Octokit::Models::Deployment)) : Array
    deployments = filter_deployments(deployments.records)
    sort_deployments(deployments)
  end
end
