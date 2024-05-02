# This file helps to "prime" or "boot" the acceptance test suite

require "emoji"
require "../src/runway/lib/logger"

log = RunwayLogger.setup_logger(ENV.fetch("LOG_LEVEL", "INFO").upcase)
ACCEPTANCE_DIR = File.dirname(__FILE__)

log.debug { "acceptance tests directory: #{ACCEPTANCE_DIR}" }
log.info { Emoji.emojize(":mag: waiting for all artifacts to be created...") }

ARTIFACTS = [
  "#{ACCEPTANCE_DIR}/projects/project-1/result.txt",
  "#{ACCEPTANCE_DIR}/logs/runway.log",
]

log.debug { "artifacts to wait for: #{ARTIFACTS}" }

TOTAL_ATTEMPTS = 300
SLEEP_DURATION = 1.second
all_artifacts_ready = false

TOTAL_ATTEMPTS.times do |attempt|
  log.debug { "attempt ##{attempt + 1}" }

  if ARTIFACTS.all? { |artifact| File.exists?(artifact) }
    log.info { Emoji.emojize(":white_check_mark: all artifacts are ready!") }
    all_artifacts_ready = true
    break
  end

  missing_artifacts = ARTIFACTS.reject { |artifact| File.exists?(artifact) }
  log.debug { "missing artifacts: #{missing_artifacts}" }

  sleep SLEEP_DURATION
end

if !all_artifacts_ready
  log.error { Emoji.emojize(":x: not all artifacts are ready!") }
  exit 1
end
