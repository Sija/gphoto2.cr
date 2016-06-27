class PortResult
  def self.as_string(rc : Int32)
    String.new LibGPhoto2.gp_port_result_as_string(rc)
  end
end
