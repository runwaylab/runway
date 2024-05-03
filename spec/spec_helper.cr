# mocking in crystal notes:
# https://www.stufro.com/2023/05/20/crystal-mocking.html
# https://gist.github.com/stufro/b4d70bbf2923ca742db617fe802a6d76

require "../src/version"
require "../src/runway/**"
require "spectator"
require "log"

CONFIG         = RunwayConfiguration.from_yaml(File.open("./config.yml"))
CONFIG_FIXTURE = RunwayConfiguration.from_yaml(File.open("./spec/fixtures/config.yml"))
EVENT          = CONFIG.projects.first.events.first
FILE_EVENT     = CONFIG_FIXTURE.projects.first.events.first
LOG            = Runway.setup_logger("ERROR")
