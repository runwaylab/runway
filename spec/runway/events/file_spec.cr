require "../../spec_helper"

Spectator.describe "FileEvent" do
  describe FileEvent do
    # Create a mock Log and event for testing
    let(log_output) { IO::Memory.new }
    let(backend) { Log::IOBackend.new(log_output, formatter: Log::ShortFormat) }
    let(log) { Log.new("test", backend, :info) }

    # Create an instance of ExampleEvent for testing
    subject { FileEvent.new(log, FILE_EVENT) }

    describe "#initialize" do
      it "creates an instance of ExampleEvent" do
        expect(subject).to be_a(FileEvent)
      end
    end

    # describe "#check_for_event" do
    #   mock File, exists?: true

    #   it "finds a deployable event" do
    #     # under the hood, this subject.check_for_event is calling the File.exists? method like so: `File.exists?("/path/to/file.txt")`
    #     # I need to capture the return value of File.exists? to return true or false for a few different tests.
    #     payload = subject.check_for_event
    #     expect(payload.ship_it?).to be_true
    #     expect(payload.run_post_deploy?).to be_true
    #   end
    # end

    # describe "#post_deploy" do
    #   it "runs post_deploy logic" do
    #     payload = subject.post_deploy(Payload.new(ship_it: true, run_post_deploy: true))
    #     expect(payload.status).to eq("success")
    #   end
    # end
  end
end
