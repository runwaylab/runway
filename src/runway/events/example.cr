require "../models/base_event"

# This class demonstrates how you can extend the BaseEvent class to create a new event type!
# Event types are defined in the config file for runway. (event.type in the config file)
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

  # If `post_deploy` is defined in the event class, it will be called after the deployment is complete and...
  # ... if the payload has a run_post_deploy? attribute set to true
  # the check_for_event method should set the run_post_deploy? attribute to true if you want this method to be called
  def post_deploy(payload : Payload) : Payload
    @log.debug { "post_deploy() payload: #{payload.inspect}" } if Runway::VERBOSE

    # exit early if the payload doesn't have a run_post_deploy? attribute
    return payload unless payload.run_post_deploy? == true

    @log.debug { "post_deploy() running post deploy logic" }

    return payload
  end

  # This method is called by the scheduler to check if the event should be handled
  # Here you will do any checks to see if the event should be handled
  # Example: Reach out to the GitHub API and see if a new release has been made that you want to upgrade to
  def check_for_event : Payload
    @log.info { "checking if a deployable event has occurred" }

    # add contitional logic here to determine if the event should be handled
    # for this example we always just return a Payload that indicates the event should be handled
    # by setting ship_it to true, we are telling the project to deploy the event when the event returns Payload with this value set to true
    # we are also letting the project know that the post_deploy method should be called by setting run_post_deploy to true
    return Payload.new(ship_it: true, run_post_deploy: true)
  end
end
