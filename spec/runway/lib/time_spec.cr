require "../../spec_helper"
require "../../../src/runway/lib/time"

describe Runway::TimeHelpers do
  describe ".interval" do
    it "returns correct Time::Span for milliseconds" do
      span = Runway::TimeHelpers.interval("100ms")
      span.total_milliseconds.should eq 100
    end

    it "returns correct Time::Span for seconds" do
      span = Runway::TimeHelpers.interval("10s")
      span.total_seconds.should eq 10
    end

    it "returns correct Time::Span for minutes" do
      span = Runway::TimeHelpers.interval("5m")
      span.total_minutes.should eq 5
    end

    it "raises an exception when invalid interval pattern is provided" do
      expect_raises Exception do
        Runway::TimeHelpers.interval("InvalidInterval")
      end
    end

    it "raises an exception when invalid interval unit is provided (hours are not supported)" do
      expect_raises Exception do
        Runway::TimeHelpers.interval("10h")
      end
    end
  end

  describe ".timezone" do
    it "returns UTC location when timezone is nil" do
      location = Runway::TimeHelpers.timezone(nil)
      location.name.should eq "UTC"
    end

    it "returns correct location when timezone is provided" do
      location = Runway::TimeHelpers.timezone("America/New_York")
      location.name.should eq "America/New_York"
    end

    it "raises an exception when invalid timezone is provided" do
      expect_raises Time::Location::InvalidLocationNameError do
        Runway::TimeHelpers.timezone("Invalid/Timezone")
      end
    end
  end
end
