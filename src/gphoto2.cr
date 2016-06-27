require "logger"

require "./ffi/*"
require "./gphoto2/*"

module GPhoto2
  @@logger : Logger?

  def self.result_as_string(rc : Int32)
    String.new LibGPhoto2.gp_result_as_string(rc)
  end

  def self.logger
    @@logger ||= begin
      logger = Logger.new(STDERR)
      logger.level = Logger::DEBUG if ENV["DEBUG"]?
      logger
    end
  end

  # @raise [GPhoto2::Error] when the return code is not {FFI::GPhoto2Port::GP_OK}
  def self.check!(rc : Int32, port_call = false)
    logger.debug "#{caller.first} (#{__FILE__}:#{__LINE__}) => #{rc}" if ENV["DEBUG"]?
    return if rc >= LibGPhoto2::GP_OK
    raise Error.new(port_call ? PortResult.as_string(rc) : result_as_string(rc), rc)
  end
end
