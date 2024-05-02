require "./spec_helper.cr"
require "../src/version"

describe Runway::VERSION do
  it "should have a version" do
    Runway::VERSION.should_not be_nil
  end

  it "should be in the following format: v0.0.0" do
    Runway::VERSION.should match(/^v\d+\.\d+\.\d+$/)
  end
end
