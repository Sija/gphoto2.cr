require "logger"
require "colorize"

require "./lib/*"
require "./gphoto2/*"

module GPhoto2
  @@logger : Logger?

  def self.logger : Logger
    @@logger ||= Logger.new(STDERR).tap do |logger|
      severity_colors = {
        Logger::Severity::UNKNOWN => :dark_gray,
        Logger::Severity::ERROR   => :light_red,
        Logger::Severity::WARN    => :red,
        Logger::Severity::INFO    => :blue,
        Logger::Severity::DEBUG   => :green,
        Logger::Severity::FATAL   => :cyan,
      }
      logger.formatter = Logger::Formatter.new do |severity, _datetime, progname, message, io|
        io << severity.to_s.rjust(5).colorize(severity_colors[severity]? || :green)
        io << " [" << progname.colorize(:cyan) << "]" unless progname.empty?
        io << " -- " << message
      end
      logger.level = Logger::DEBUG if debug?
    end
  end

  if debug?
    gp_logger = ->(level : LibGPhoto2::GPLogLevel, _domain : LibC::Char*, str : LibC::Char*, _data : Void*) {
      severities = {
        LibGPhoto2::GPLogLevel::Error   => Logger::Severity::ERROR,
        LibGPhoto2::GPLogLevel::Verbose => Logger::Severity::INFO,
        LibGPhoto2::GPLogLevel::Debug   => Logger::Severity::DEBUG,
      }
      logger.log severities[level], String.new(str), "libgphoto2"
    }
    gp_log_level = LibGPhoto2::GPLogLevel.parse(ENV["LIB_LOG_LEVEL"]? || "debug")
    LibGPhoto2.gp_log_add_func(gp_log_level, gp_logger, nil)
  end

  macro log(*args, severity = Logger::Severity::DEBUG, backtrace_offset = 0)
    if ::GPhoto2.debug? && {{!args.empty?}}
      %DEBUG_CALLER_PATTERN = /caller:Array\(String\)/i
      %caller_list = caller.dup
      if %caller_list.any? &.match(%DEBUG_CALLER_PATTERN)
        while !%caller_list.empty? && %caller_list.first? !~ %DEBUG_CALLER_PATTERN
          %caller_list.shift?
        end
        %caller_list.shift?
      end
      {% if backtrace_offset > 0 %}
        %caller_list.shift {{backtrace_offset}}
      {% end %}
      %str = String.build do |%str|
        if %caller = %caller_list.first?
          %str << %caller.colorize(:dark_gray)
          %str << " -- "
        end
        %str << "{{args}} = ".colorize(:light_gray) << {{args}}
      end
      ::GPhoto2.logger.log {{severity.id}}, %str, "gphoto2.cr"
    end
  end

  def self.debug?
    ENV["DEBUG"]? == "1"
  end

  def self.library_version(verbose = LibGPhoto2::GPVersionVerbosity::Short) : String
    String.new LibGPhoto2.gp_library_version(verbose).value
  end

  def self.result_as_string(rc : Int32) : String
    String.new LibGPhoto2.gp_result_as_string(rc)
  end

  def self.check?(rc : Int32) : Bool
    rc >= LibGPhoto2::GP_OK
  end

  def self.check!(rc : Int32) : Int32
    log(rc, backtrace_offset: 1)
    return rc if check?(rc)
    raise Error.from_code(rc)
  end
end
