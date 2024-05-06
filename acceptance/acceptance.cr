require "spec"
require "emoji"
require "../src/runway/core/logger"

log = Runway.setup_logger(ENV.fetch("LOG_LEVEL", "INFO").upcase)
ACCEPTANCE_DIR = File.dirname(__FILE__)
UUID_REGEX     = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i
SEMVER_REGEX   = /v\d+\.\d+\.\d+/

log.debug { "acceptance tests directory: #{ACCEPTANCE_DIR}" }
log.info { Emoji.emojize("🧪 starting acceptance test suite") }

def load_and_scrub_logs(file_path)
  File.read_lines(file_path).map do |line|
    line = line.gsub(UUID_REGEX, "<UUID>")
    line = line.gsub(SEMVER_REGEX, "<SEMVER>")
    line
  end
end

expected_logs = load_and_scrub_logs(File.join(ACCEPTANCE_DIR, "logs", "expected.log"))
actual_logs = load_and_scrub_logs(File.join(ACCEPTANCE_DIR, "logs", "runway.log"))

# ensure that the actual logs contain the expected logs, for this test case order does not matter
describe "runway" do
  describe "expected log output" do
    expected_logs.each do |expected_log|
      it "contains the expected log: #{expected_log[0..23]}..." do
        actual_logs.includes?(expected_log).should be_true
      end
    end
  end

  describe "artifacts" do
    it "contains the expected number of artifacts" do
      Dir.glob(File.join(ACCEPTANCE_DIR, "projects", "project-1", "*.txt")).size.should eq(1)
    end

    it "the result.txt artifact contains the correct data" do
      File.read(File.join(ACCEPTANCE_DIR, "projects", "project-1", "result.txt")).strip.should eq("success")
    end

    it "the result-remote.txt artifact contains the correct data" do
      File.read(File.join(ACCEPTANCE_DIR, "logs", "result-remote.txt")).strip.should eq("path: acceptance/projects/project-2/ship-it.txt")
    end
  end
end
