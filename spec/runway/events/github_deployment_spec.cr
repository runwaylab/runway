require "../../spec_helper"

Spectator.describe "GitHubDeployment" do
  describe GitHubDeployment do
    inject_mock Octokit::Client

    # Create a mock Log and event for testing
    let(log_output) { IO::Memory.new }
    let(backend) { Log::IOBackend.new(log_output, formatter: Log::ShortFormat) }
    let(log) { Log.new("test", backend, :info) }
    let(octokit) { Octokit::Client.new(access_token: "fake_token") }
    let(deployments) do
      File.read("spec/fixtures/github/deployments.json")
    end
    let(all_dev_deployments) do
      File.read("spec/fixtures/github/all_dev_deployments.json")
    end
    let(deployment_statuses) do
      File.read("spec/fixtures/github/deployment_statuses.json")
    end
    let(create_deployment) do
      File.read("spec/fixtures/github/create_deployment.json")
    end

    subject { GitHubDeployment.new(log, GITHUB_DEPLOYMENT_EVENT) }

    before do
      expect(Octokit::Client).to receive(:new).and_return(octokit)
    end

    describe "#initialize" do
      it "creates an instance of GitHubDeployment" do
        expect(subject).to be_a(GitHubDeployment)
      end
    end

    # describe "#post_deploy" do
    #   before_each do
    #     allow(octokit).to receive(:check_rate_limit!)
    #       .and_return(nil)
    #   end

    #   it "runs post_deploy logic and cleans up the file which triggered it" do
    #     expect(octokit).to receive(:create_deployment_status)
    #       .with("runwaylab/test-flight", 123456789, "success")
    #       .and_return(create_deployment)

    #     payload = Payload.new(
    #       ship_it: true,
    #       run_post_deploy: true,
    #       success: true,
    #       id: "123456789"
    #     )

    #     payload = subject.post_deploy(payload)
    #     expect(payload.status).to eq("success")
    #   end
    # end
  end
end
