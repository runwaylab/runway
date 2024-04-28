require "../../../spec_helper"
require "../../../../src/runway/models/events/example"

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

  describe "#check_for_event and #handle_event runs" do
    it "runs both" do
      # Call the methods
      subject.check_for_event
      subject.handle_event
    end
  end

  describe "check logs" do
    it "checks the logs" do
      # Check the log output
      log_output.to_s.should contain("checking if a deployable event has occurred") #
      log_output.to_s.should contain("processing a deployment event!")
    end
  end
end
