require "../base_event"
require "../../services/github"

class GitHubDeployment < BaseEvent
  EventRegistry.register_event("github_deployment", self)
  @deployment_filter : Int32
  @repo : String

  def initialize(log : Log, event : Event)
    super(log, event)
    @github = Runway::GitHub.new(log)
    @client = @github.client
    @deployment_filter = (@event.deployment_filter.try(&.to_i) || 1)
    @repo = @event.repo.not_nil!
    @timezone = Runway::TimeHelpers.timezone(@event.schedule.timezone)
    @success = "success"
    @failure = "failure"
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

    @log.info { Emoji.emojize(":hammer_and_wrench:  handling a deployment event for #{@repo} in the #{@event.environment} environment") }

    deployment_id = payload.id.to_s.to_i64.not_nil!
    status = payload.status.not_nil!

    # create a deployment status
    result = Retriable.retry do
      @github.check_rate_limit!
      @client.create_deployment_status(@repo, deployment_id, status)
    end

    @log.debug { "deployment status result: #{JSON.parse(result).to_pretty_json}" } if Runway::VERBOSE

    raise "Unexpected deployment status result" unless JSON.parse(result)["state"] == @success

    # logs about the deployment status
    @log.info { Emoji.emojize(":rocket: successfully deployed #{@repo} to the #{@event.environment} environment!") } if status == @success
    @log.error { Emoji.emojize(":x: deployment failed for #{@repo} in the #{@event.environment} environment") } if status != @success

    return payload
  rescue error : Exception
    @log.error { "error handling deployment event: #{error.message} - attempting to set a 'failure' statue on the deployment" }
    result = Retriable.retry do
      @github.check_rate_limit!
      @client.create_deployment_status(@repo, payload.id.to_s.to_i64.not_nil!, @failure)
    end

    @log.debug { "deployment status result (on error): #{JSON.parse(result).to_pretty_json}" }
    return payload
  end

  # Check for a GitHub deployment event in the specified environment
  # This method uses post_deploy hooks to create a deployment status for the deployment after a deployment completes/fails
  def check_for_event : Payload
    payload = Payload.new(ship_it: false, run_post_deploy: true)

    @log.debug { "received a check_for_event() request for event.uuid: #{@event.uuid}" }
    @log.info { "checking #{@repo} for a #{@event.environment} deployment event" } unless Runway::QUIET
    deployments = Retriable.retry do
      @github.check_rate_limit!
      @client.deployments(@repo, {"environment" => @event.environment.not_nil!})
    end

    @log.debug { "GitHubDeployment -> check_for_event() deployments: #{deployments}" } if Runway::VERBOSE
    deployments = JSON.parse(deployments)

    deployments = filter_deployments(deployments)
    deployments = sort_deployments(deployments)

    detected_deployment = find_in_progress_deployment(deployments)

    # exit early if we didn't find a deployment in_progress
    return payload unless detected_deployment

    # set the payload attributes
    payload.id = detected_deployment["id"].to_s.not_nil!
    payload.environment = detected_deployment.try(&.["environment"]).try(&.to_s) || nil
    payload.created_at = detected_deployment.try(&.["created_at"]).try(&.to_s) || nil
    payload.updated_at = detected_deployment.try(&.["updated_at"]).try(&.to_s) || nil
    payload.description = detected_deployment.try(&.["description"]).try(&.to_s) || nil
    payload.user = detected_deployment.try(&.["creator"]).try(&.["login"]).try(&.to_s) || nil
    payload.sha = detected_deployment.try(&.["sha"]).try(&.to_s) || nil
    payload.ref = detected_deployment.try(&.["ref"]).try(&.to_s) || nil
    payload.status = "in_progress"
    payload.ship_it = true

    # logging for debugging purposes
    @log.warn { Emoji.emojize(":warning: deployment sha is missing from the deployment payload") } if payload.sha.nil?
    @log.debug { "in_progress deployment sha for #{@repo}: #{payload.sha}" }
    @log.warn { Emoji.emojize(":warning: deployment ref is missing from the deployment payload") } if payload.ref.nil?
    @log.debug { "in_progress deployment ref for #{@repo}: #{payload.ref}" }

    return payload
  end

  def filter_deployments(deployments : JSON::Any) : Array
    # filter deployments by environment
    # this should already have been done by the GitHub API, but we'll do it again out of extra caution
    deployments = deployments.as_a.select do |deployment|
      deployment["environment"] == @event.environment
    end

    return deployments
  end

  def sort_deployments(deployments : Array) : Array
    # sort deployments by created_at date with the most recent first
    deployments = deployments.sort_by do |deployment|
      Time.parse(deployment["created_at"].as_s, "%FT%T%z", @timezone)
    end.reverse!

    # only grab the X most recent deployments (based on event.filters.deployments)
    return deployments.first(@deployment_filter)
  end

  def find_in_progress_deployment(deployments : Array) : JSON::Any?
    # loop through all filtered deployments and get their deployment statuses
    # the first deployment to have an "in_progress" status will be the one we're looking for
    # however, the "in_progress" status must be the most recent status for the deployment or we'll ignore it
    deployments.each do |deployment|
      deployment_id = deployment["id"].to_s.to_i
      statuses = Retriable.retry do
        @github.check_rate_limit!
        @client.list_deployment_statuses(@event.repo.not_nil!, deployment_id)
      end
      statuses = JSON.parse(statuses.records.to_json)

      # sort statuses by created_at date with the most recent first
      statuses = statuses.as_a.sort_by do |status|
        Time.parse(status["created_at"].as_s, "%FT%T%z", @timezone)
      end.reverse!

      # if the most recent status is "in_progress", we have our deployment
      if statuses.first["state"] == "in_progress"
        @log.debug { "found an in_progress deployment for #{@repo} in the #{@event.environment} environment" }
        return deployment
      end
    end

    # if we've reached this point, we didn't find a deployment in_progress
    return nil
  end
end
