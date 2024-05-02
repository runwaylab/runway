require "../../../spec_helper"
require "../../../../src/runway/events/example"

Spectator.describe "ExampleEvent" do
  describe ExampleEvent do
    # Create a mock Log and Event for testing
    let(log_output) { IO::Memory.new }
    let(backend) { Log::IOBackend.new(log_output, formatter: Log::ShortFormat) }
    let(log) { Log.new("test", backend, :info) }

    # Create an instance of ExampleEvent for testing
    subject { ExampleEvent.new(log, EVENT) }

    describe "#initialize" do
      it "creates an instance of ExampleEvent" do
        expect(subject).to be_a(ExampleEvent)
      end
    end

    describe "#check_for_event" do
      it "finds a deployable event" do
        payload = subject.check_for_event
        expect(payload.ship_it?).to be_true
        expect(payload.run_post_deploy?).to be_true
      end

      it "runs post_deploy logic" do
        payload = subject.post_deploy(Payload.new(ship_it: true, run_post_deploy: true))
        expect(payload.status).to eq("success")
      end
    end
  end
end
