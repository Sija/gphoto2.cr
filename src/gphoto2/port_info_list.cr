require "./struct"

module GPhoto2
  class PortInfo; end

  class PortInfoList
    include GPhoto2::Struct(FFI::LibGPhoto2Port::GPPortInfoList)

    def initialize
      new
      load
    end

    def lookup_path(port)
      _lookup_path(port)
    end

    def index(port)
      lookup_path(port)
    end

    def at(index : Int32) : PortInfo
      PortInfo.new(self, index)
    end

    def [](index) : PortInfo
      at(index)
    end

    private def new
      GPhoto2.check! FFI::LibGPhoto2Port.gp_port_info_list_new(out ptr)
      self.ptr = ptr
    end

    private def load
      GPhoto2.check! FFI::LibGPhoto2Port.gp_port_info_list_load(self)
    end

    private def _lookup_path(port : String) : Int32
      GPhoto2.check! FFI::LibGPhoto2Port.gp_port_info_list_lookup_path(self, port)
    end
  end
end