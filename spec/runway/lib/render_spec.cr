require "../../spec_helper"

Spectator.describe "Render" do
  let(payload) { Payload.new(ref: "cool-feature-branch", id: "123", environment: "production") }

  subject { Runway::Render.new }

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

    it "renders a string with a payload" do
      bindings = {payload: payload.to_h}
      result = subject.render("deploying ref: {{ payload.ref }} to {{ payload.environment }}!", bindings)
      expect(result).to eq("deploying ref: cool-feature-branch to production!")
    end

    it "fails to render a payload with an unknown object" do
      bindings = {payload: payload.to_h}
      expect_raises Crinja::RuntimeError do
        subject.render("deploying ref: {{ payload.ref }} to {{ payload.environment }} on {{ oops.missing }}!", bindings)
      end
    end

    it "renders a string with a payload that is missing an attribute" do
      bindings = {payload: payload.to_h}
      result = subject.render("deploying ref: {{ payload.ref }} to {{ payload.environment }} on {{ payload.missing }}!", bindings)
      expect(result).to eq("deploying ref: cool-feature-branch to production on !")
    end

    it "raises an error when a key in the bindings doesn't exist" do
      bindings = {name: "World"}
      expect_raises Crinja::RuntimeError do
        subject.render("Hello, {{ oops.bad }}!", bindings)
      end
    end
  end
end
