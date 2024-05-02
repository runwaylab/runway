require "../../spec_helper"

Spectator.describe "logger" do
  describe Runway do
    describe "setup_logger" do
      it "should return a logger" do
        logger = Runway.setup_logger("ERROR")
        expect(logger).to be_a(Log)
        expect(logger.level).to eq(Log::Severity::Error)
      end
    end
  end
end
