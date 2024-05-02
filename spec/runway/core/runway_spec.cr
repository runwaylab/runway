require "../../spec_helper"

Spectator.describe "runway" do
  describe Runway::Core do
    describe ".new" do
      it "creates a new instance of Runway::Core" do
        expect(Runway::Core.new(LOG, CONFIG_FIXTURE)).to be_instance_of(Runway::Core)
      end
    end
  end
end
