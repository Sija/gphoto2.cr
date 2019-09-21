require "debug"

require "./lib/*"
require "./gphoto2/*"

Debug.configure do |settings|
  settings.location_detection = :runtime
  settings.max_path_length = nil
end

Debug::Logger.configure do |settings|
  settings.progname = "gphoto2.cr"
end

module GPhoto2
  if Debug.enabled?
    gp_logger = ->(level : LibGPhoto2::GPLogLevel, _domain : LibC::Char*, str : LibC::Char*, _data : Void*) {
      severities = {
        LibGPhoto2::GPLogLevel::Error   => Logger::Severity::ERROR,
        LibGPhoto2::GPLogLevel::Verbose => Logger::Severity::INFO,
        LibGPhoto2::GPLogLevel::Debug   => Logger::Severity::DEBUG,
      }
      Debug.logger.log severities[level], String.new(str), "libgphoto2"
    }
    gp_log_level = LibGPhoto2::GPLogLevel.parse(ENV["LIB_LOG_LEVEL"]? || "debug")
    LibGPhoto2.gp_log_add_func(gp_log_level, gp_logger, nil)
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
    Debug.log(rc, backtrace_offset: 1)
    if check?(rc)
      rc
    else
      raise Error.from_code(rc)
    end
  end
end
