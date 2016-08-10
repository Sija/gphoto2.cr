require "./struct"

module GPhoto2
  class CameraAbilitiesList
    include Struct(LibGPhoto2::CameraAbilitiesList)

    @context : Context

    def initialize(@context : Context)
      new
      load
    end

    def detect : CameraList
      _detect
    end

    def lookup_model(model : String) : Int32
      _lookup_model(model)
    end

    def index(model : String) : Int32
      lookup_model(model)
    end

    def at(index : Int32) : CameraAbilities
      CameraAbilities.new(self, index)
    end

    def [](index : Int32) : CameraAbilities
      at(index)
    end

    private def new
      GPhoto2.check! LibGPhoto2.gp_abilities_list_new(out ptr)
      self.ptr = ptr
    end

    private def load
      @context.check! LibGPhoto2.gp_abilities_list_load(self, @context)
    end

    private def _detect
      port_info_list = PortInfoList.new
      camera_list = CameraList.new

      @context.check! LibGPhoto2.gp_abilities_list_detect(self, port_info_list, camera_list, @context)
      camera_list
    end

    private def _lookup_model(model)
      GPhoto2.check! LibGPhoto2.gp_abilities_list_lookup_model(self, model)
    end
  end
end
