require "option_parser"
require "log"
require "emoji"
require "colorize"
require "./runway/models/config"
require "./runway/core/runway"
require "./runway/core/logger"

module Runway
  module Cli
    def self.run
      opts = self.opts

      log = Runway.setup_logger(opts[:log_level])
      log.info { Emoji.emojize(":book: loading runway configuration") }

      log.debug { "attempting to load config from #{opts[:config_path]}" }
      config = RunwayConfiguration.from_yaml(File.open(opts[:config_path]))
      log.info { Emoji.emojize(":white_check_mark: loaded configuration successfully") }
      log.info { Emoji.emojize(":truck: #{config.projects.size} #{config.projects.size == 1 ? "project" : "projects"} loaded") }

      Runway::Core.new(log, config).start!
    end

    # Parse command line options
    def self.opts : Hash(Symbol, String)
      opts = {} of Symbol => String

      # first, get the defaults from the environment
      opts[:config_path] = ENV.fetch("RUNWAY_CONFIG", "config.yml")
      opts[:log_level] = ENV.fetch("LOG_LEVEL", "INFO")

      # then, parse the command line options
      OptionParser.parse do |parser|
        parser.banner = "Usage: runway [arguments]"
        parser.on("-c FILE", "--config=FILE", "path to runway config file") { |config_file| opts[:config_path] = config_file }
        parser.on("-l LEVEL", "--log-level=LEVEL", "sets the log level") { |level| opts[:log_level] = level }
        parser.on("-h", "--help", "Show this help") do
          puts parser
          exit 0
        end
        parser.invalid_option do |flag|
          STDERR.puts "ERROR: #{flag} is not a valid option"
          STDERR.puts parser
          exit(1)
        end
      end

      # return the parsed options
      return opts
    end
  end
end

Runway::Cli.run
