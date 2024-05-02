require "../../spec_helper"
require "../../../src/runway/lib/common"

Spectator.describe "Runway::Common" do
  describe Runway::Common do
    let(crons) do
      [
        "0 0 * * *",
        "* * * * *",
        "0 22 * * 1-5",
        "0 */5 13,18 * * *",
        "0 0-5 13 * * *",
        "0 30 9 * * MON-FRI",
        "0 30 9 15 * *",
        "0 0 0 */5 * *",
      ]
    end

    let(non_crons) { ["", " ", "1s", "1m", "1h", "1d", "1w", "1m", "1y"] }

    describe ".cron?" do
      context "with valid cron strings" do
        it "returns true for valid cron strings" do
          crons.each do |value|
            expect(Runway::Common.cron?(value)).to be_true
          end
        end
      end

      context "with non-cron strings" do
        it "returns false for non-cron strings" do
          non_crons.each do |value|
            expect(Runway::Common.cron?(value)).to be_false
          end
        end
      end
    end
  end
end
