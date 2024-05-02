require "../src/version"
require "../src/runway/**"
require "spectator"
require "log"

CONFIG         = RunwayConfiguration.from_yaml(File.open("./config.yml"))
CONFIG_FIXTURE = RunwayConfiguration.from_yaml(File.open("./spec/fixtures/config.yml"))
EVENT          = CONFIG.projects.first.events.first
LOG            = Runway.setup_logger("ERROR")
