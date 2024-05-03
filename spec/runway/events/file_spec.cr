require "../../spec_helper"

Spectator.describe "FileEvent" do
  describe FileEvent do
    inject_mock FS # mock out the fs.cr module

    # Create a mock Log and event for testing
    let(log_output) { IO::Memory.new }
    let(backend) { Log::IOBackend.new(log_output, formatter: Log::ShortFormat) }
    let(log) { Log.new("test", backend, :info) }
    let(test_file) { "test1.txt" }

    # Create an instance of ExampleEvent for testing
    subject { FileEvent.new(log, FILE_EVENT) }

    describe "#initialize" do
      it "creates an instance of ExampleEvent" do
        expect(subject).to be_a(FileEvent)
      end
    end

    describe "#check_for_event" do
      it "finds a deployable event" do
        expect(FS).to receive(:exists?).with(test_file).and_return(true)
        payload = subject.check_for_event
        expect(payload.ship_it?).to be_true
        expect(payload.run_post_deploy?).to be_true
      end

      it "does not find a deployable event" do
        expect(FS).to receive(:exists?).with(test_file).and_return(false)
        payload = subject.check_for_event
        expect(payload.ship_it?).to be_false
        expect(payload.run_post_deploy?).to be_false
      end
    end

    describe "#post_deploy" do
      it "runs post_deploy logic and cleans up the file which triggered it" do
        expect(FS).to receive(:exists?).with(test_file).and_return(true)
        expect(FS).to receive(:delete).with(test_file).and_return(nil)
        payload = subject.post_deploy(Payload.new(ship_it: true, run_post_deploy: true))
        expect(payload.status).to eq("success")
      end
    end
  end
end
