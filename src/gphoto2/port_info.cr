require "./struct"

module GPhoto2
  class PortInfo
    include GPhoto2::Struct(LibGPhoto2Port::GPPortInfo)

    def self.find(port : String) : self
      port_info_list = PortInfoList.new
      port_info_list[port]
    end

    # Returns the name of the port.
    def name : String
      get_name.not_nil!
    end

    # Returns the path of the port.
    def path : String
      get_path.not_nil!
    end

    # Returns the type of the port.
    def type : Port::Type
      get_type
    end

    private def get_name
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_get_name(self, out ptr)
      String.new ptr if ptr
    end

    private def get_path
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_get_path(self, out ptr)
      String.new ptr if ptr
    end

    private def get_type
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_get_type(self, out type)
      type
    end
  end
end
