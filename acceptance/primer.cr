# This file helps to "prime" or "boot" the acceptance test suite

require "emoji"
require "../src/runway/core/logger"

log = Runway.setup_logger(ENV.fetch("LOG_LEVEL", "INFO").upcase)
ACCEPTANCE_DIR = File.dirname(__FILE__)

log.debug { "acceptance tests directory: #{ACCEPTANCE_DIR}" }
log.info { Emoji.emojize(":zap: setting up the acceptance test suite for a fresh run") }

FILES_TO_CREATE = [
  "#{ACCEPTANCE_DIR}/projects/project-1/ship-it.txt",
]

log.debug { "creating files: #{FILES_TO_CREATE}..." }

FILES_TO_CREATE.each do |file|
  log.debug { "creating file: #{file}" }
  File.touch(file) unless File.exists?(file)
end

FILES_TO_DELETE = [
  "#{ACCEPTANCE_DIR}/projects/project-1/result.txt",
  "#{ACCEPTANCE_DIR}/logs/runway.log",
]

FILES_TO_DELETE.each do |file|
  log.debug { "deleting file: #{file}" }
  File.delete(file) if File.exists?(file)
end
