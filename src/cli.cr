require "option_parser"
require "log"
require "emoji"
require "colorize"
require "./models/config"
require "./runway"

module Runway
  module Cli
    def self.run
      opts = self.opts

      log = self.logger(opts[:log_level])
      log.info { Emoji.emojize(":book: loading runway configuration") }

      log.debug { "attempting to load config from #{opts[:config_path]}" }
      config = RunwayConfiguration.from_yaml(File.open(opts[:config_path]))
      log.info { Emoji.emojize(":white_check_mark: loaded configuration successfully") }

      Runway.start(log, config)
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

    # setup a logger for the entire application
    # :param log_level: the log level to set
    # :return: a Log instance
    def self.logger(log_level) : Log
      Log.setup_from_env
      log = Log.for("runway")
      log.level = case log_level
                  when "DEBUG" then Log::Severity::Debug
                  when "INFO"  then Log::Severity::Info
                  when "WARN"  then Log::Severity::Warn
                  when "ERROR" then Log::Severity::Error
                  else              raise "Invalid log level: #{log_level}"
                  end

      # only use colors if we are on a tty
      colors : Bool = Colorize.on_tty_only!

      # setup a custom formatter that even supports colors
      formatter = Log::Formatter.new do |entry, io|
        message = entry.message

        logger_colors = {
          Log::Severity::Error => :red,
          Log::Severity::Warn  => :yellow,
          Log::Severity::Info  => :green,
          Log::Severity::Debug => :light_gray,
        }

        # get the severity label and make it uppercase
        severity_label = entry.severity.to_s.upcase

        if colors
          io << if color = logger_colors[entry.severity]?
            severity_label.colorize(color).to_s + ": " + message
          else
            severity_label + ": " + message
          end
        else
          io << severity_label + ": " + message
        end
      end

      log.backend = Log::IOBackend.new(formatter: formatter)

      log.debug { "log level set to #{log_level}" }

      return log
    end
  end
end

Runway::Cli.run
