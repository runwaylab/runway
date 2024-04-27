require "spec"
require "../src/models/config"

CONFIG = RunwayConfiguration.from_yaml(File.open("./config.yml"))
EVENT  = CONFIG.projects.first.events.first

CRONS = [
  "0 0 * * *",
  "* * * * *",
  "0 22 * * 1-5",
  "0 */5 13,18 * * *",
  "0 0-5 13 * * *",
  "0 30 9 * * MON-FRI",
  "0 30 9 15 * *",
  "0 0 0 */5 * *",
]
