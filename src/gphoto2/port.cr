require "./struct"

module GPhoto2
  class Port
    include GPhoto2::Struct(LibGPhoto2Port::GPPort)

    alias Type = LibGPhoto2Port::GPPortType

    def initialize
      new
    end

    def finalize
      free
    end

    def info : PortInfo
      get_info
    end

    def info=(info : PortInfo) : PortInfo
      set_info(info)
      info
    end

    def open : Nil
      _open
    end

    def close : Nil
      _close
    end

    def reset : Nil
      _reset
    end

    private def new
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_new(out ptr)
      self.ptr = ptr
    end

    private def free
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_free(self)
      self.ptr = nil
    end

    private def _open
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_open(self)
    end

    private def _close
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_close(self)
    end

    private def _reset
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_reset(self)
    end

    private def get_info
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_get_info(self, out port_info)
      PortInfo.new(port_info)
    end

    private def set_info(port_info)
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_set_info(self, port_info)
    end
  end
end
