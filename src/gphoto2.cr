require "logger"
require "colorize"

require "./lib/*"
require "./gphoto2/*"

module GPhoto2
  @@logger : Logger?

  def self.logger : Logger
    @@logger ||= begin
      severity_colors = {
        "UNKNOWN" => :dark_gray,
        "ERROR"   => :light_red,
        "WARN"    => :red,
        "INFO"    => :blue,
        "DEBUG"   => :green,
        "FATAL"   => :cyan
      }
      logger = Logger.new(STDERR)
      logger.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
        io << severity.rjust(5).colorize(severity_colors[severity]? || :green)
        io << " [" << progname.colorize(:cyan) << "]" unless progname.empty?
        io << " -- " << message
      end
      logger.level = Logger::DEBUG if debug?
      logger
    end
  end

  gp_logger = ->(level : LibGPhoto2::GPLogLevel, domain : LibC::Char*, str : LibC::Char*, data : Void*) {
    severities = {
      LibGPhoto2::GPLogLevel::Error   => Logger::Severity::ERROR,
      LibGPhoto2::GPLogLevel::Verbose => Logger::Severity::INFO,
      LibGPhoto2::GPLogLevel::Debug   => Logger::Severity::DEBUG
    }
    logger.log severities[level], String.new(str), "libgphoto2"
  }
  if debug?
    gp_log_level = LibGPhoto2::GPLogLevel.parse ENV["LIB_LOG_LEVEL"]? || "debug"
    LibGPhoto2.gp_log_add_func gp_log_level, gp_logger, nil
  end

  macro log(*args, severity = Logger::Severity::DEBUG, backtrace_offset = 1)
    if GPhoto2.debug?
      %caller_list = caller.dup
      while !%caller_list.empty? && %caller_list.first? !~ /caller:Array\(String\)/i
        %caller_list.shift?
      end
      %caller_list.shift {{backtrace_offset}}
      unless %caller_list.empty?
        str = String.build do |str|
          {% if backtrace_offset > 1 %}
            str << %caller_list.first.colorize(:dark_gray)
          {% end %}
          {% if !args.empty? %}
            {% if backtrace_offset > 1 %}
              str << " -- "
            {% end %}
            str << "{{args}} = ".colorize(:light_gray) << {{args}}
          {% end %}
        end
        GPhoto2.logger.log {{severity.id}}, str, "gphoto2.cr"
      end
    end
  end

  def self.debug?
    ENV["DEBUG"]? == "1"
  end

  def self.result_as_string(rc : Int32)
    String.new LibGPhoto2.gp_result_as_string(rc)
  end

  def self.library_version(verbose = LibGPhoto2::GPVersionVerbosity::Short)
    String.new LibGPhoto2.gp_library_version(verbose).value
  end

  def self.check!(rc : Int32) : Int32
    log(rc, backtrace_offset: 2)
    return rc if check?(rc)
    raise Error.new(result_as_string(rc), rc)
  end
  
  def self.check?(rc : Int32) : Bool
    rc >= LibGPhoto2::GP_OK
  end
end
