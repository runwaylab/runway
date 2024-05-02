require "../../spec_helper"
require "../../../src/runway/lib/retry"

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
