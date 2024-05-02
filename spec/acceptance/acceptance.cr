require "spec"
require "emoji"
require "../../src/runway/lib/logger"

log = RunwayLogger.setup_logger(ENV.fetch("LOG_LEVEL", "INFO").upcase)
ACCEPTANCE_DIR = File.dirname(__FILE__)

log.debug { "acceptance tests directory: #{ACCEPTANCE_DIR}" }
log.info { Emoji.emojize("🧪 starting acceptance test suite") }
