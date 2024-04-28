module RunwayLogger
  # setup a logger for the entire application
  # :param log_level: the log level to set
  # :return: a Log instance
  def self.setup_logger(log_level : String) : Log
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
