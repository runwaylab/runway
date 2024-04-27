require "octokit"
require "../lib/logger"

module Runway
  class GitHub
    @client : Octokit::Client

    def initialize(log : Log, token : String? = ENV.fetch("GITHUB_TOKEN", nil))
      @log = log
      @client = create_client(token)
    end

    protected def create_client(token) : Octokit::Client
      if (token.nil? || token.empty?) && ENV.fetch("SUPPRESS_STARTUP_WARNINGS", nil).nil?
        @log.warn { "No GitHub token provided. Please set the GITHUB_TOKEN environment variable to avoid excessive rate limiting." }
      end

      # octokit.cr wipes out the loggers, so we need to re-apply them
      # fetch the current log level
      log_level = @log.level

      # create the client
      client = Octokit::Client.new(access_token: token)
      client.auto_paginate = true
      client.per_page = 100

      @log = RunwayLogger.setup_logger(log_level.to_s.upcase)

      return client
    end
  end
end
