require "../../spec_helper"

Spectator.describe "Retry" do
  describe Retry do
    describe ".setup!" do
      it "configures Retriable with correct settings without raising an error" do
        logger = Log.for("test")
        Retry.setup!(logger)
      end
    end
  end
end
