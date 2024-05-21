require "octokit"
require "../core/logger"

module Runway
  class GitHub
    @miniumum_rate_limit : Int32
    @client : Octokit::Client

    # The octokit class for interacting with GitHub's API
    # @param log [Log] the logger to use
    # @param token [String?] the GitHub token to use for authentication - if nil, the client will be unauthenticated
    def initialize(log : Log, token : String? = ENV.fetch("GITHUB_TOKEN", nil))
      @log = log
      @client = create_client(token)
      @miniumum_rate_limit = ENV.fetch("GITHUB_MINIMUM_RATE_LIMIT", "10").to_s.to_i
    end

    def create_deployment_status(repo : String, deployment_id : Int64, status : String) : String
      Retriable.retry do
        check_rate_limit!
        @client.create_deployment_status(repo, deployment_id, status)
      end
    end

    def list_deployment_statuses(repo : String, deployment_id : Int32, per_page : Int32 = 30) : Octokit::Connection::Paginator(Octokit::Models::DeploymentStatus)
      Retriable.retry do
        check_rate_limit!
        @client.list_deployment_statuses(repo, deployment_id, per_page: per_page)
      end
    end

    def deployments(repo : String, environment : String) : String
      Retriable.retry do
        check_rate_limit!
        @client.deployments(repo, {"environment" => environment})
      end
    end

    # A helper method to check the rate limit of the GitHub API
    # if the rate limit is exceeded, we'll wait until the rate limit resets
    # this is a blocking operation
    def check_rate_limit!
      # Octokit::RateLimit(@limit=5000, @remaining=4278, @resets_at=2024-04-29 06:23:52.0 UTC, @resets_in=1784)
      rate_limit = nil
      begin
        rate_limit = @client.rate_limit
      rescue ex : KeyError
        error_message = ex.message.not_nil!
        if error_message.includes?("Missing hash key: HTTP::Headers::Key(@name=\"X-RateLimit-Limit\")")
          # https://github.com/runwaylab/runway/issues/25
          @client.get("rate_limit")
          rate_limit = @client.rate_limit
        else
          raise ex
        end
      end

      rate_limit = rate_limit.not_nil!

      # if rate_limit.remaining is nil, exit early
      if rate_limit.remaining.nil?
        @log.warn { "the GitHub API rate limit is nil - waiting 60 seconds before checking again" }
        sleep(60)
        return
      end

      # if the rate limit is below the minimum, we'll wait until the rate limit resets
      rate_limit_remaining = rate_limit.remaining.try(&.to_i).not_nil!
      if rate_limit_remaining < @miniumum_rate_limit
        resets = rate_limit.resets_in.try(&.to_i).not_nil!
        reset_sleep = resets + 1
        @log.warn { "the GitHub API rate limit is almost exceeded - waiting #{resets} seconds until the rate limit resets" }
        @log.debug { "GitHub rate_limit.remaining: #{rate_limit.remaining} - rate_limit.resets_at: #{rate_limit.resets_at} - rate_limit.resets_in: #{rate_limit.resets_in} - sleeping: #{reset_sleep} seconds" }
        sleep(reset_sleep + 1)
      end
    end

    # Creates an octokit.cr client with the given token (can be nil aka unauthenticated)
    # @param token [String?] the GitHub token to use for authentication - if nil, the client will be unauthenticated
    # @return [Octokit::Client] the client
    protected def create_client(token : String?) : Octokit::Client
      if (token.nil? || token.empty?) && ENV.fetch("SUPPRESS_STARTUP_WARNINGS", nil).nil?
        @log.warn { "No GitHub token provided. Please set the GITHUB_TOKEN environment variable to avoid excessive rate limiting." }
      end

      # octokit.cr wipes out the loggers, so we need to re-apply them... bleh
      # fetch the current log level
      log_level = @log.level

      # create the client
      client = Octokit::Client.new(access_token: token)
      client.auto_paginate = ENV.fetch("OCTOKIT_CR_AUTO_PAGINATE", "true") == "true"
      client.per_page = ENV.fetch("OCTOKIT_CR_PER_PAGE", "100").to_i

      @log = Runway.setup_logger(log_level.to_s.upcase)

      return client
    end
  end
end
