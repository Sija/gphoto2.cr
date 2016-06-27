require "logger"

require "./ffi/*"
require "./gphoto2/*"

module GPhoto2
  @@logger : Logger?

  def self.result_as_string(rc : Int32)
    String.new FFI::LibGPhoto2.gp_result_as_string(rc)
  end

  def self.logger
    @@logger ||= begin
      logger = Logger.new(STDERR)
      logger.level = Logger::DEBUG if ENV["DEBUG"]?
      logger
    end
  end

  def self.check!(rc : Int32)
    return if rc >= FFI::LibGPhoto2::GP_OK
    raise Error.new(result_as_string(rc), rc)
  end
end
