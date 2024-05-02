require "../../spec_helper"
require "../../../src/runway/lib/common"

describe Runway::Common do
  crons = [
    "0 0 * * *",
    "* * * * *",
    "0 22 * * 1-5",
    "0 */5 13,18 * * *",
    "0 0-5 13 * * *",
    "0 30 9 * * MON-FRI",
    "0 30 9 15 * *",
    "0 0 0 */5 * *",
  ]

  non_crons = ["", " ", "1s", "1m", "1h", "1d", "1w", "1m", "1y"]

  describe ".cron?" do
    context "with valid cron strings" do
      crons.each do |value|
        it "returns true for '#{value}'" do
          Runway::Common.cron?(value).should eq true
        end
      end
    end

    context "with non-cron strings" do
      non_crons.each do |value|
        it "returns false for '#{value}'" do
          Runway::Common.cron?(value).should eq false
        end
      end
    end
  end
end
