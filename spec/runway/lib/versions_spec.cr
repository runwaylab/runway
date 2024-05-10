require "../../spec_helper"

Spectator.describe "Versions" do
  subject { Runway::Versions }

  describe Versions do
    it "finds that the current version and the latest version are the same" do
      expect(subject.upgradable?("1.1.0", "1.1.0", ">= 1.0.0")).to be_nil
    end

    it "finds that there is an upgradable version" do
      expect(subject.upgradable?("1.1.0", "1.1.1", ">= 1.0.0")).to be_truthy
    end

    it "finds that there is no compatible version to upgrade to" do
      expect(subject.upgradable?("1.40.0", "2.0.0", "~> 1.0")).to be_falsey
    end

    it "finds that it cannot be upgraded due to a strict version constraint" do
      expect(subject.upgradable?("1.0.0", "1.1.0", "= 1.0.0")).to be_falsey
    end

    it "finds that the current version is up-to-date but doesn't match the requirement" do
      expect(subject.upgradable?("1.1.0", "1.1.0", ">= 1.2.0")).to be_falsey
    end

    it "finds that the current version is not up-to-date but the latest version doesn't match the requirement" do
      expect(subject.upgradable?("1.1.0", "1.2.0", ">= 1.3.0")).to be_falsey
    end

    it "finds that the current version is not up-to-date but the latest version matches the requirement" do
      expect(subject.upgradable?("1.1.0", "1.2.0", ">= 1.1.0")).to be_truthy
    end

    it "finds that the current version is up-to-date and matches a strict requirement" do
      expect(subject.upgradable?("1.1.0", "1.1.0", "= 1.1.0")).to be_nil
    end

    it "finds that the current version is not up-to-date but matches a strict requirement" do
      expect(subject.upgradable?("1.1.0", "1.2.0", "= 1.1.0")).to be_falsey
    end

    it "finds that the current version is less than or equal to the requirement" do
      expect(subject.upgradable?("1.1.0", "1.1.1", "<= 1.2.0")).to be_truthy
    end

    it "finds that the current version is greater than the requirement" do
      expect(subject.upgradable?("1.3.0", "1.3.1", "> 1.2.0")).to be_truthy
    end

    it "finds that the current version is less than the requirement" do
      expect(subject.upgradable?("1.1.0", "1.1.1", "< 1.2.0")).to be_truthy
    end

    it "finds that the current version is not equal to the requirement" do
      expect(subject.upgradable?("1.1.0", "1.1.1", "!= 1.1.0")).to be_truthy
    end

    it "finds that the latest version is compatible with !=" do
      expect(subject.upgradable?("1.1.0", "1.1.1", "!= 1.2.0")).to be_truthy
    end

    it "finds that the current version is equal to the prerelease version" do
      expect(subject.upgradable?("1.1.0", "1.1.0-alpha", ">= 1.1.0")).to be_falsey
    end

    it "finds that the current version is less than the prerelease version" do
      expect(subject.upgradable?("1.1.0", "1.1.0-alpha", ">= 1.1.0")).to be_falsey
    end

    it "finds a four digit version to be upgradable" do
      expect(subject.upgradable?("1.1.0", "1.0.0.0", ">= 1.0.0")).to be_truthy
    end

    it "finds that the prerelease version can be upgraded" do
      expect(subject.upgradable?("1.1.0-alpha", "1.1.0", ">= 1.1.0")).to be_truthy
    end
  end
end
