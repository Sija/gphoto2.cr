require "./struct"

module GPhoto2
  # Represents a list of camera abilities.
  class CameraAbilitiesList
    include Struct(LibGPhoto2::CameraAbilitiesList)

    @context : Context

    # The list of ports used by `#detect`, loaded on first use (unless given),
    # since loading it takes a while, while it's not needed for lookups.
    private getter port_info_list : PortInfoList { PortInfoList.new }

    # Loads the abilities of all supported camera models, using the given
    # *context*, along with the *port_info_list* used by `#detect`.
    #
    # NOTE: allocates memory.
    def initialize(@context, @port_info_list : PortInfoList? = nil)
      new
      load
    end

    # Finalizes object by freeing allocated memory.
    def finalize
      close
    end

    # Frees allocated memory.
    #
    # NOTE: The list of all supported models takes up several megabytes,
    # allocated outside of the GC heap, so it's best to free it right
    # after use, instead of waiting for the GC.
    def close : Nil
      free if ptr?
    end

    # Returns the list of the detected cameras, with their model names and ports.
    def detect : CameraList
      _detect
    end

    # Returns the index of the given *model* in the list.
    #
    # Raises `GPhoto2::Error` if the model isn't supported.
    def lookup_model(model : String) : Int32
      _lookup_model(model)
    end

    # Returns the abilities of the camera model at the given *index*.
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
        LibGPhoto2.gp_abilities_list_detect(self, port_info_list, camera_list, @context)
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
