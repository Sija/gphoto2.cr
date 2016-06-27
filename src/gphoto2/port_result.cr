class PortResult
  def self.as_string(rc : Int32)
    String.new FFI::LibGPhoto2.gp_port_result_as_string(rc)
  end

  def self.check!(rc : Int32)
    return if rc >= FFI::LibGPhoto2::GP_OK
    raise Error.new(as_string(rc), rc)
  end
end
