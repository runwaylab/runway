require "../base_event"
require "../../services/github"

class GitHubDeployment < BaseEvent
  EventRegistry.register_event("github_deployment", self)

  def initialize(log : Log, event : Event)
    super(log, event)
    @client = Runway::GitHub.new(log)
  end

  def handle_event
    @log.info { "Handling GitHub Deployment event" }
  end

  def check_for_event
    @log.info { "Checking for GitHub Deployment event" }
  end
end