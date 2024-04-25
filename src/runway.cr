module Runway
  def self.start(log, config)
    log.info { Emoji.emojize(":airplane: starting runway") }
    log.info { "#{config. projects.size} #{config.projects.size == 1 ? "project" : "projects"} loaded" }
  end
end
