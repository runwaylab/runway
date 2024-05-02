require "../../spec_helper"
require "../../../src/runway/lib/time"

Spectator.describe "Runway::TimeHelpers" do
  describe Runway::TimeHelpers do
    describe ".interval" do
      it "returns correct Time::Span for milliseconds" do
        span = Runway::TimeHelpers.interval("100ms")
        expect(span.total_milliseconds).to eq 100
      end

      it "returns correct Time::Span for seconds" do
        span = Runway::TimeHelpers.interval("10s")
        expect(span.total_seconds).to eq 10
      end

      it "returns correct Time::Span for minutes" do
        span = Runway::TimeHelpers.interval("5m")
        expect(span.total_minutes).to eq 5
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
        expect(location.name).to eq "UTC"
      end

      it "returns correct location when timezone is provided" do
        location = Runway::TimeHelpers.timezone("America/New_York")
        expect(location.name).to eq "America/New_York"
      end

      it "raises an exception when invalid timezone is provided" do
        expect_raises Time::Location::InvalidLocationNameError do
          Runway::TimeHelpers.timezone("Invalid/Timezone")
        end
      end
    end
  end
end
