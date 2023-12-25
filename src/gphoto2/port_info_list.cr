require "./struct"

module GPhoto2
  class PortInfoList
    include GPhoto2::Struct(LibGPhoto2Port::GPPortInfoList)

    # NOTE: allocates memory.
    def initialize
      new
      load
    end

    # Finalizes object by freeing allocated memory.
    def finalize
      free
    end

    def lookup_path(port : String) : Int32
      _lookup_path(port)
    end

    def [](index : Int32) : PortInfo
      get_info(index)
    end

    # See: `#lookup_path`, `#[]`
    def [](port : String) : PortInfo
      index = lookup_path(port)
      self[index]
    end

    private def new
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_list_new(out ptr)
      self.ptr = ptr
    end

    private def free
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_list_free(self)
      self.ptr = nil
    end

    private def load
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_list_load(self)
    end

    private def count
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_list_count(self)
    end

    private def _lookup_path(port)
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_list_lookup_path(self, port)
    end

    private def get_info(index)
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_list_get_info(self, index, out info)
      PortInfo.new info
    end
  end
end
