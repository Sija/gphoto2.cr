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
    #
    # NOTE: The memory might not have been allocated at all (i.e. when
    # `#initialize` failed), and raising from a finalizer is not an option.
    def finalize
      free if ptr?
    end

    # Returns number of entries in the list.
    def size : Int32
      count
    end

    # Returns the index of the given *port* path in the list.
    #
    # Raises `GPhoto2::Error` if the port isn't found, or `ArgumentError`
    # if *port* contains a null byte (which would make libgphoto2 look up
    # the port given by the part before it).
    def lookup_path(port : String) : Int32
      _lookup_path(port)
    end

    # Returns info of the port at the given *index*.
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
        LibGPhoto2Port.gp_port_info_list_lookup_path(self, port.check_no_null_byte)
    end

    private def get_info(index)
      GPhoto2.check! \
        LibGPhoto2Port.gp_port_info_list_get_info(self, index, out info)
      PortInfo.new(info, self)
    end
  end
end
