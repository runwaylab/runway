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
  end

  def handle_event(payload)
    @log.debug { "received a handle_event() request for deployment.id: #{payload["id"]} from event.uuid: #{@event.uuid}" }
    @log.info { Emoji.emojize(":hammer_and_wrench:  handling a deployment event for #{@repo} in the #{@event.environment} environment") }

    # create a success deployment status
    result = Retriable.retry do
      @github.check_rate_limit!
      @client.create_deployment_status(@repo, payload["id"].to_s.to_i, "success")
    end

    @log.debug { "deployment status result: #{JSON.parse(result).to_pretty_json}" } if Runway::VERBOSE

    raise "Unexpected deployment status result" unless JSON.parse(result)["state"] == "success"

    @log.info { Emoji.emojize(":rocket: successfully deployed #{@repo} to the #{@event.environment} environment!") }

    return true
  rescue error : Exception
    @log.error { "error handling deployment event: #{error.message}" }
    result = Retriable.retry do
      @github.check_rate_limit!
      @client.create_deployment_status(@repo, payload["id"].to_s.to_i, "failure")
    end

    @log.debug { "deployment status result (on error): #{JSON.parse(result).to_pretty_json}" }
    return false
  end

  def check_for_event
    @log.debug { "received a check_for_event() request for event.uuid: #{@event.uuid}" }
    @log.info { "checking #{@repo} for a #{@event.environment} deployment event" } unless Runway::QUIET
    deployments = Retriable.retry do
      @github.check_rate_limit!
      @client.deployments(@repo, {"environment" => @event.environment.not_nil!})
    end
    deployments = JSON.parse(deployments)

    # filter deployments by environment
    # this should already have been done by the GitHub API, but we'll do it again out of extra caution
    deployments = deployments.as_a.select do |deployment|
      deployment["environment"] == @event.environment
    end

    # sort deployments by created_at date with the most recent first
    deployments = deployments.sort_by do |deployment|
      Time.parse(deployment["created_at"].as_s, "%FT%T%z", @timezone)
    end.reverse!

    # only grab the X most recent deployments (based on event.filters.deployments)
    deployments = deployments.first(@deployment_filter)

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
        @log.debug { "found a deployment in_progress deployment for #{@repo} in the #{@event.environment} environment" }

        if deployment["sha"].nil?
          @log.warn { Emoji.emojize(":warning: deployment sha is missing from the deployment payload") }
        else
          @log.debug { "in_progress deployment sha for #{@repo}: #{deployment["sha"]}" }
        end

        return handle_event(deployment)
      end
    end
  end
end
