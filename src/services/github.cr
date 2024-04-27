require "octokit"
require "../lib/logger"

module Runway
  class GitHub
    @client : Octokit::Client

    # The octokit class for interacting with GitHub's API
    # @param log [Log] the logger to use
    # @param token [String?] the GitHub token to use for authentication - if nil, the client will be unauthenticated
    def initialize(log : Log, token : String? = ENV.fetch("GITHUB_TOKEN", nil))
      @log = log
      @client = create_client(token)
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

      @log : Log = RunwayLogger.setup_logger(log_level.to_s.upcase)

      return client
    end
  end
end
