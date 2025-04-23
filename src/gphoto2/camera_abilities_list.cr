require "./struct"

module GPhoto2
  # Represents a list of camera abilities.
  class CameraAbilitiesList
    include Struct(LibGPhoto2::CameraAbilitiesList)

    @context : Context
    @port_info_list : PortInfoList

    # NOTE: allocates memory.
    def initialize(@context, @port_info_list = PortInfoList.new)
      new
      load
    end

    # Finalizes object by freeing allocated memory.
    def finalize
      free
    end

    def detect : CameraList
      _detect
    end

    def lookup_model(model : String) : Int32
      _lookup_model(model)
    end

    def [](index : Int32) : CameraAbilities
      get_abilities(index)
    end

    # See: `#lookup_model`, `#[]`
    def [](model : String) : CameraAbilities
      index = lookup_model(model)
      self[index]
    end

    private def new
      GPhoto2.check! \
        LibGPhoto2.gp_abilities_list_new(out ptr)
      self.ptr = ptr
    end

    private def free
      GPhoto2.check! \
        LibGPhoto2.gp_abilities_list_free(self)
      self.ptr = nil
    end

    private def load
      @context.check! \
        LibGPhoto2.gp_abilities_list_load(self, @context)
    end

    private def _detect
      camera_list = CameraList.new
      @context.check! \
        LibGPhoto2.gp_abilities_list_detect(self, @port_info_list, camera_list, @context)
      camera_list
    end

    private def _lookup_model(model)
      GPhoto2.check! \
        LibGPhoto2.gp_abilities_list_lookup_model(self, model)
    end

    private def get_abilities(index)
      GPhoto2.check! \
        LibGPhoto2.gp_abilities_list_get_abilities(self, index, out abilities)
      CameraAbilities.new pointerof(abilities)
    end
  end
end
