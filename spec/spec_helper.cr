require "spec"
require "log"
require "../src/runway/core/env"
require "../src/runway/models/config"

CONFIG = RunwayConfiguration.from_yaml(File.open("./config.yml"))
EVENT  = CONFIG.projects.first.events.first
