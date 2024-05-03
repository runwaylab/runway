require "../models/base_event"
require "../lib/fs"

# This class demonstrates is mostly used for acceptance tests but can be used for actual deployment events too!
# This event handler is extremely simple and just looks for the existence of a file in the directory
# If the file exists, that is considered a deployable event
# The post_deploy hook will delete the file after the deployment is complete so be mindful of that - unless the cleanup flag is set to false
class FileEvent < BaseEvent
  EventRegistry.register_event("file", self) # where "file" matches the event.type from the config file

  @path : String
  @cleanup : Bool

  def initialize(log : Log, event : Event)
    super(log, event)
    @path = event.path.not_nil!
    @cleanup = event.cleanup.not_nil!
  end

  # Run post deploy logic to clean up the file
  def post_deploy(payload : Payload) : Payload
    @log.debug { "post_deploy() payload: #{payload.inspect}" } if Runway::VERBOSE

    # exit early if the payload doesn't have a run_post_deploy? attribute
    return payload unless payload.run_post_deploy? == true

    @log.debug { "post_deploy() running post deploy logic for event.type #{@event.type} - event.uuid #{@event.uuid}" }

    # delete the file if the cleanup flag is set to true
    FS.delete(@path) if @cleanup == true && FS.exists?(@path)

    @log.debug { "post_deploy() post deploy logic complete for event.type #{@event.type} - event.uuid #{@event.uuid}" }
    payload.status = "success"
    return payload
  end

  # Check to see if the `file` exists
  def check_for_event : Payload
    @log.info { "checking if file '#{@path}' exists" } unless Runway::QUIET

    # check to see if the file exists
    if FS.exists?(@path)
      @log.info { "file exists at path: #{@path}" }
    else
      @log.info { "file does not exist at path: #{@path}" }

      # exit early if the file does not exist
      return Payload.new(ship_it: false)
    end

    # the file has been found and a deployable event has occurred!
    return Payload.new(ship_it: true, run_post_deploy: true, path: @path)
  end
end
