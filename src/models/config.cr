require "yaml"

# https://crystal-lang.org/api/1.12.1/YAML/Serializable.html
class RunwayConfiguration
  include YAML::Serializable
  property projects : Array(Project)
end

class Project
  include YAML::Serializable
  property name : String
  property type : String
  property location : String
  property path : String
end
