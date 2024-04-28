require "../base_event"

# This class demonstrates how you can extend the BaseEvent class to create a new event type!
# Event types are defined in the config file for run way.
# This class defines how events are "checked" when their schedule runs and how they are "handled" when a deployment should be made
#
# You should copy/paste this entire file as a starting point for creating a new event type
class ExampleEvent < BaseEvent
  EventRegistry.register_event("example_event", self) # where "example_event" matches the event.type from the config file

  # This is the constructor for the class. It is required to call the super constructor with the log and event
  # After calling super, you can do any additional setup you need for your event
  # See the `github_deployment.cr` file for an example of how to do additional setup
  def initialize(log : Log, event : Event)
    super(log, event) # this is required
  end

  # If `check_for_event` determines that the event should be handled, call this method next!
  # This method will actually handle the event and make the deployment. For example, if you want to deploy a new release...
  # ... you might write custom code here to deploy the new release
  def handle_event
    @log.info { "processing a deployment event!" }
  end

  # This method is called by the scheduler to check if the event should be handled
  # Here you will do any checks to see if the event should be handled
  # Example: Reach out to the GitHub API and see if a new release has been made that you want to upgrade to
  def check_for_event
    @log.info { "checking if a deployable event has occurred" }
  end
end
