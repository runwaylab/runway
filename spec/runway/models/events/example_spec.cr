require "../../../spec_helper"
require "../../../../src/runway/events/example"

describe ExampleEvent do
  # Create a mock Log and Event for testing
  log_output = IO::Memory.new
  backend = Log::IOBackend.new(log_output, formatter: Log::ShortFormat)
  log = Log.new("test", backend, :info)

  # Create an instance of ExampleEvent for testing
  subject = ExampleEvent.new(log, EVENT)

  describe "#initialize" do
    it "creates an instance of ExampleEvent" do
      subject.should be_a(ExampleEvent)
    end
  end

  describe "#check_for_event" do
    it "finds a deployable event" do
      payload = subject.check_for_event
      payload.ship_it?.should be_true
      payload.run_post_deploy?.should be_true
    end

    it "runs post_deploy logic" do
      payload = subject.post_deploy(Payload.new(ship_it: true, run_post_deploy: true))
      payload.status.should eq("success")
    end
  end
end
