require "../base_event"

class GitHubDeployment < BaseEvent
  EventRegistry.register_event("github_deployment", self)

  def initialize(log : Log, event : Event)
    super(log, event)
  end

  def handle_event
    @log.info { "Handling GitHub Deployment event" }
  end

  def check_for_event
    @log.info { "Checking for GitHub Deployment event" }
  end
end
