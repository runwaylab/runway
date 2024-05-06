require "../../spec_helper"

Spectator.describe "Render" do
  subject do
    Runway::Render.new
  end

  describe Render do
    it "renders a string without bindings" do
      result = subject.render("Hello, World!")
      expect(result).to eq("Hello, World!")
    end

    it "renders a string with bindings" do
      bindings = {name: "World"}
      result = subject.render("Hello, {{ name }}!", bindings)
      expect(result).to eq("Hello, World!")
    end

    it "raises an error when a key in the bindings doesn't exist" do
      bindings = {name: "World"}
      expect_raises Crinja::RuntimeError do
        subject.render("Hello, {{ oops.bad }}!", bindings)
      end
    end
  end
end
