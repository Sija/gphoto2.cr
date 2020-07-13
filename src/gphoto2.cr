require "debug"

require "./lib/*"
require "./gphoto2/*"

{% if Debug::ACTIVE %}
  Debug.configure do |settings|
    settings.location_detection = :runtime
    settings.max_path_length = nil
  end

  Debug::Logger.settings.progname = "gphoto2.cr"

  if Debug.enabled?
    gp_log_level = LibGPhoto2::GPLogLevel.parse(ENV["LIB_LOG_LEVEL"]? || "debug")
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

  def library_version(verbosity : LibGPhoto2::GPVersionVerbosity = :short) : String
    String.new LibGPhoto2.gp_library_version(verbosity).value
  end

  def result_as_string(rc : Int32) : String
    String.new LibGPhoto2.gp_result_as_string(rc)
  end

  def check?(rc : Int32) : Bool
    rc >= LibGPhoto2::GP_OK
  end

  def check!(rc : Int32) : Int32
    Debug.log(rc, backtrace_offset: 1)
    if check?(rc)
      rc
    else
      raise Error.from_code(rc)
    end
  end
end
