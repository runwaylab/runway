require "../src/runway"
require "./spec_helper"

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
