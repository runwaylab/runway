require "./spec_helper.cr"
require "../src/version"

describe Runway do
  it "should have a version" do
    Runway::VERSION.should_not be_nil
  end
end
