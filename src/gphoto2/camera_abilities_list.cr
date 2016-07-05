require "./struct"

module GPhoto2
  class PortInfoList; end
  class CameraList; end
  class CameraAbilities; end

  class CameraAbilitiesList
    include Struct(FFI::LibGPhoto2::CameraAbilitiesList)

    @context : Context

    def initialize(@context)
      new
      load
    end

    def detect
      _detect
    end

    def lookup_model(model)
      _lookup_model(model)
    end

    def index(model)
      lookup_model(model)
    end

    def at(index : Int32)
      CameraAbilities.new(self, index)
    end

    def [](index)
      at(index)
    end

    private def new
      GPhoto2.check! FFI::LibGPhoto2.gp_abilities_list_new(out ptr)
      self.ptr = ptr
    end

    private def load
      GPhoto2.check! FFI::LibGPhoto2.gp_abilities_list_load(self, @context)
    end

    private def _detect
      port_info_list = PortInfoList.new
      camera_list = CameraList.new

      GPhoto2.check! FFI::LibGPhoto2.gp_abilities_list_detect(
        self,
        port_info_list,
        camera_list,
        @context
      )
      camera_list
    end

    private def _lookup_model(model : String) : Int32
      GPhoto2.check! FFI::LibGPhoto2.gp_abilities_list_lookup_model(self, model)
    end
  end
end
