require "./spec_helper.cr"
require "../src/version"

Spectator.describe "Runway::VERSION" do
  describe Runway::VERSION do
    it "should have a version" do
      expect(Runway::VERSION).to_not be_nil
    end

    it "should be in the following format: v0.0.0" do
      expect(Runway::VERSION).to match(/^v\d+\.\d+\.\d+$/)
    end
  end
end
