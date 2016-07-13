require "./struct"

module GPhoto2
  class PortInfo
    include GPhoto2::Struct(LibGPhoto2Port::GPPortInfo)

    @port_info_list : PortInfoList
    @index : Int32

    def self.find(port : String)
      port_info_list = PortInfoList.new
      index = port_info_list.lookup_path(port)
      port_info_list[index]
    end

    def initialize(@port_info_list, @index)
      new
    end

    def name
      get_name
    end

    def path
      get_path
    end

    def type
      get_type
    end

    private def new
      GPhoto2.check! LibGPhoto2Port.gp_port_info_list_get_info(@port_info_list, @index, out ptr)
      self.ptr = ptr
    end

    private def get_name : String?
      GPhoto2.check! LibGPhoto2Port.gp_port_info_get_name(self, out ptr)
      !ptr ? nil : String.new ptr
    end

    private def get_path : String?
      GPhoto2.check! LibGPhoto2Port.gp_port_info_get_path(self, out ptr)
      !ptr ? nil : String.new ptr
    end

    private def get_type : LibGPhoto2Port::GPPortType
      GPhoto2.check! LibGPhoto2Port.gp_port_info_get_type(self, out type)
      type
    end
  end
end