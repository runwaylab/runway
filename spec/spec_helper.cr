require "../src/version"
require "../src/runway/**"
require "spectator"
require "log"

CONFIG = RunwayConfiguration.from_yaml(File.open("./config.yml"))
EVENT  = CONFIG.projects.first.events.first
