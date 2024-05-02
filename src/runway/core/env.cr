module Runway
  ERROR_PREFIX    = ":boom: error while checking for event:"
  SCHEDULE_PREFIX = ":clock1: scheduling event with"
  QUIET           = ENV.fetch("RUNWAY_QUIET", "false") == "true"   # suppress the logs a bit
  VERBOSE         = ENV.fetch("RUNWAY_VERBOSE", "false") == "true" # print very verbose debug logs
end
