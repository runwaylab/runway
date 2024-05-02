require "../../../src/runway/lib/common"
require "../../spec_helper"

CRONS = [
  "0 0 * * *",
  "* * * * *",
  "0 22 * * 1-5",
  "0 */5 13,18 * * *",
  "0 0-5 13 * * *",
  "0 30 9 * * MON-FRI",
  "0 30 9 15 * *",
  "0 0 0 */5 * *",
]

module Runway
  describe ".cron?" do
    CRONS.each do |value|
      it "returns true if it is a cron job (#{value})" do
        Runway::Common.cron?(value).should eq true
      end
    end

    ["", " ", "1s", "1m", "1h", "1d", "1w", "1m", "1y"].each do |value|
      it "returns false if it is not a cron job (#{value})" do
        Runway::Common.cron?(value).should eq false
      end
    end
  end
end
