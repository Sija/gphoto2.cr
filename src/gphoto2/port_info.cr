require "./struct"

module GPhoto2
  class PortInfo
    include GPhoto2::Struct(LibGPhoto2Port::GPPortInfo)

    @port_info_list : PortInfoList
    @index : Int32

    def self.find(port : String) : self
      port_info_list = PortInfoList.new
      index = port_info_list.lookup_path(port)
      port_info_list[index]
    end

    def initialize(@port_info_list : PortInfoList, @index : Int32)
      new
    end

    def name : String
      get_name.not_nil!
    end

    def path : String
      get_path.not_nil!
    end

    def type : LibGPhoto2Port::GPPortType
      get_type
    end

    private def new
      GPhoto2.check! LibGPhoto2Port.gp_port_info_list_get_info(@port_info_list, @index, out ptr)
      self.ptr = ptr
    end

    private def get_name
      GPhoto2.check! LibGPhoto2Port.gp_port_info_get_name(self, out ptr)
      !ptr ? nil : String.new ptr
    end

    private def get_path
      GPhoto2.check! LibGPhoto2Port.gp_port_info_get_path(self, out ptr)
      !ptr ? nil : String.new ptr
    end

    private def get_type
      GPhoto2.check! LibGPhoto2Port.gp_port_info_get_type(self, out type)
      type
    end
  end
end
