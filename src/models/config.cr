require "yaml"

# https://crystal-lang.org/api/1.12.1/YAML/Serializable.html

class RunwayConfiguration
  include YAML::Serializable
  property projects : Array(Project)
end

# A project is a collection of events that trigger deployments and are run on a schedule
class Project
  include YAML::Serializable
  property name : String
  property type : String
  property location : String
  property path : String
  property events : Array(Event)
end

# An event is a trigger for a deployment for a project
class Event
  include YAML::Serializable
  property type : String
  property repo : String?
end

# A schedule is a cron or interval schedule that is run for an event
class Schedule
  include YAML::Serializable
  property type : String
  property interval : String?
  property cron : String?
end
