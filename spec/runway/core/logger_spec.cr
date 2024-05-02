require "../../spec_helper"

Spectator.describe "logger" do
  describe Runway do
    describe "setup_logger" do
      it "should return a logger" do
        logger = Runway.setup_logger("DEBUG")
        expect(logger).to be_a(Log)
        expect(logger.level).to eq(Log::Severity::Debug)
      end
    end
  end
end
