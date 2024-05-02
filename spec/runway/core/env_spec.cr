require "../../spec_helper"

Spectator.describe "env" do
  describe Runway do
    describe "env" do
      it "makes sure the VERBOSE env is a string" do
        expect(Runway::VERBOSE).to be_a(Bool)
      end
    end
  end
end
