require "debug"

require "./lib/*"
require "./gphoto2/*"

{% if Debug::ACTIVE %}
  Debug.configure do |settings|
    settings.location_detection = :runtime
    settings.max_path_length = nil
  end

  if Debug.enabled?
    gp_log_level = GPhoto2::LogLevel.parse(ENV["LIB_LOG_LEVEL"]? || "debug")
    gp_logger =
      ->(level : LibGPhoto2::GPLogLevel, _domain : LibC::Char*, str : LibC::Char*, _data : Void*) {
        proc = ->(emitter : Log::Emitter) do
          emitter.emit(String.new(str), progname: "libgphoto2")
        end
        logger = Debug.logger
        case level
        in .error?   then logger.error &proc
        in .verbose? then logger.notice &proc
        in .debug?   then logger.debug &proc
        end
      }
    LibGPhoto2.gp_log_add_func(gp_log_level, gp_logger, nil)
  end
{% end %}

module GPhoto2
  extend self

  alias VersionVerbosity = LibGPhoto2::GPVersionVerbosity
  alias LogLevel = LibGPhoto2::GPLogLevel

  # Returns the GPhoto2 library version.
  def library_version(verbosity : VersionVerbosity = :short) : String
    String.new LibGPhoto2.gp_library_version(verbosity).value
  end

  # Returns the GPhoto2 return code (*rc*) as a string.
  def result_as_string(rc : Int32) : String
    String.new LibGPhoto2.gp_result_as_string(rc)
  end

  # Checks if the given *rc* is a GPhoto2 error code.
  def check?(rc : Int32) : Bool
    rc >= LibGPhoto2::GP_OK
  end

  def check!(rc : Int32) : Int32
    Debug.log(rc, backtrace_offset: 1, progname: "gphoto2.cr")
    if check?(rc)
      rc
    else
      raise Error.from_code(rc)
    end
  end
end
